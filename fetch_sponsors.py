#! /usr/bin/python3

import os
import re
import sys
from collections import Counter
from launchpadlib.launchpad import Launchpad

def get_first_activity_date(bug, target_person_link):
    """
    Optimized: Compares raw URL strings to avoid 'Hydrating' person objects.
    """
    for activity in bug.activity:
        # person_link is a string; target_person_link is a string. 0 network calls.
        if activity.person_link == target_person_link:
            return activity.datechanged
    return bug.date_created

def get_sponsor_from_activity(bug, target_statuses):
    """
    Finds the last person to move the bug into a 'fixed' state.
    """
    try:
        for activity in reversed(bug.activity):
            if activity.whatchanged == 'status' and activity.newvalue in target_statuses:
                # We only fetch the display_name once we've found our match
                return activity.person.display_name
    except Exception:
        pass
    return "Unknown"

def run_sru_audit(target_username):
    cachedir = os.path.expanduser("~/.launchpadlib/cache/")
    lp = Launchpad.login_with('sru-tracker-parser', 'production', cachedir, version='devel')

    try:
        person = lp.people[target_username]
        # Pre-fetch the link to use for lightning-fast comparisons
        target_person_link = person.self_link
    except KeyError:
        print(f"User '{target_username}' not found.")
        return

    target_statuses = ["Fix Committed", "Fix Released"]
    
    # --- PHASE 1: DISCOVERY (Instant Printing) ---
    print(f"\n[PHASE 1] Discovering bugs for {target_username}...")
    print(f"{'Bug ID':<8} | {'Status':<15} | {'Title'}")
    print("-" * 80)

    tasks = person.searchTasks(status=target_statuses, assignee=person)
    unique_tasks = []
    seen_bug_ids = set()

    for task in tasks:
        bug = task.bug
        if bug.id not in seen_bug_ids and "-proposed tracker" in bug.title.lower():
            # Instant printing as we find them
            print(f"{bug.id:<8} | {task.status:<15} | {bug.title[:55]}...")
            seen_bug_ids.add(bug.id)
            unique_tasks.append(task)

    if not unique_tasks:
        print("\nNo matching tracker bugs found.")
        return

    total_bugs = len(unique_tasks)
    print(f"\nTotal bugs found: {total_bugs}")
    print("="*80)

    # --- PHASE 2: PROCESSING (With Progress Bar) ---
    print(f"[PHASE 2] Starting deep parse of {total_bugs} bugs...")
    results = []
    sponsor_counts = Counter()

    for i, task in enumerate(unique_tasks, 1):
        bug = task.bug
        
        # Calculate percentage and update the progress line
        percent = (i / total_bugs) * 100
        # \r moves the cursor to the start of the line; sys.stdout.flush() ensures immediate visibility
        sys.stdout.write(f"\r> Progress: {percent:3.0f}% | Processing Bug #{bug.id} ({i}/{total_bugs})")
        sys.stdout.flush()
        
        title = bug.title
        
        # 1. Distro & Version Parsing
        distro = title.split('/')[0].strip() if '/' in title else "N/A"
        version = "N/A"
        if ':' in title:
            after_colon = title.split(':', 1)[1]
            version = after_colon.replace("-proposed tracker", "").strip()

        # 2. People & Dynamic Date
        first_activity_dt = get_first_activity_date(bug, target_person_link)
        date_str = first_activity_dt.strftime('%Y-%m-%d %H:%M')
        sponsoree = person.display_name
        sponsor = ""#get_sponsor_from_activity(bug, target_statuses)
        if "-riscv" in bug.description:
            sponsor = "Mehmet Basaran"
        elif "-gcp" in bug.description or "-oracle" in bug.description:
            sponsor = "Timo Aaltonen"
        elif "-bluefield" in bug.description:
            sponsor = "Kuba Pawlak"
        elif "-kvm" in bug.description:
            sponsor = "Bethany Jamison"


        # 3. Parse Description for Packages
        desc = bug.description
        pkg_section = re.search(r'packages:\s*\n((?:\s+.*\n?)+)', desc)
        
        packages = []
        if pkg_section:
            lines = pkg_section.group(1).splitlines()
            for line in lines:
                if ':' in line:
                    pkg_val = line.split(':', 1)[1].strip()
                    if pkg_val:
                        packages.append(pkg_val)
        
        if not packages:
            match = re.search(r'/(.*?):', title)
            fallback_pkg = match.group(1).strip() if match else title.split(':')[0].strip()
            packages.append(fallback_pkg)

        for pkg in packages:
            sponsor_counts[sponsor] += 1
            results.append({
                'dt': first_activity_dt,
                'line': f"|| {date_str} || {sponsor} || {sponsoree} || {pkg} || {version} || {distro} ||"
            })

    # Move to next line after progress bar finishes
    print("\n" + "="*80)

    # --- OUTPUT SUMMARY TABLE ---
    print("\n|| Sponsor || Count ||")
    total_pkgs = 0
    # Sort sponsors by count descending
    for s_name, count in sponsor_counts.most_common():
        print(f"|| {s_name} || {count} ||")
        total_pkgs += count
    print(f"|| Total || {total_pkgs} ||")

    # Sort results by date (oldest first)
    results.sort(key=lambda x: x['dt'])

    # --- FINAL OUTPUT ---
    print("\nFINAL REPORT (Sorted by First Activity Date):")
    print("|| Date || Sponsor || Sponsoree || Package || Version || Distribution ||")
    for r in results:
        print(r['line'])

if __name__ == "__main__":
    # Target User
    run_sru_audit("alessiofaina")

