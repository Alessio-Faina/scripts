#! /usr/bin/env python3

# Written by Alessio Faina <alessio.faina@canonical.com>

import os
import re
import sys
import urllib.request

ktml_address:str = "http://ktml-board.kernel/archive/?q="

def find_highest_patch_version(ktml_query_result):
    version = 1
    for line in ktml_query_result:
        strline = line.decode("utf-8").upper()
        if "[PATCH V" in strline:
            test_version = strline.split("[PATCH V")[1][:1]
            test_version_int = int(test_version)
            if test_version_int > version:
                version = test_version_int
    return str(version)

def find_kernel_series(line:str):
    series = ""
    m = re.match(r".*\[SRU\](\[.*\])\[PATCH.*].*", line, re.X)
    if m:
        series = m.group(1)
    return series

class status:
    acks : int = 0
    applied : int = 0
    nacks : int = 0
    warning : int = 0
    occurrencies: int = 0
    deleteme : bool = False

class status_per_series:
    def __init__(self):
        self.status_per_series = dict()
    
    def add_ack(self, series:str):
        if not series in self.status_per_series.keys():
            tmp = status()
            tmp.acks = 1
            self.status_per_series[series] = tmp
        else:
            self.status_per_series[series].acks += 1

    def add_nack(self, series:str):
        if not series in self.status_per_series.keys():
            tmp = status()
            tmp.nacks = 1
            self.status_per_series[series] = tmp
        else:
            self.status_per_series[series].nacks += 1

    def add_applied(self, series:str):
        if not series in self.status_per_series.keys():
            tmp = status()
            tmp.applied = 1
            self.status_per_series[series] = tmp
        else:
            self.status_per_series[series].applied += 1

    def add_warning(self, series:str):
        if not series in self.status_per_series.keys():
            tmp = status()
            tmp.warning = 1
            self.status_per_series[series] = tmp
        else:
            self.status_per_series[series].warning += 1

    def add_exists(self, series:str):
        if not series in self.status_per_series.keys():
            tmp = status()
            tmp.occurrencies = 1
            self.status_per_series[series] = tmp

    def normalise_keys(self):
        for key in self.status_per_series.keys():
            for key2 in self.status_per_series.keys():
                if key == key2:
                    continue
                if key.replace('[','').replace(']','') in key2:
                    s2 = self.status_per_series[key2]
                    s1 = self.status_per_series[key]
                    s2.acks += s1.acks
                    s2.nacks += s1.nacks
                    s2.applied += s1.applied
                    s2.warning += s1.warning
                    s1.deleteme = True
                if key2.replace('[','').replace(']','') in key:
                    s2 = self.status_per_series[key2]
                    s1 = self.status_per_series[key]
                    s1.acks += s2.acks
                    s1.nacks += s2.nacks
                    s1.applied += s2.applied
                    s1.warning += s2.warning
                    s2.deleteme = True

        for key in list(self.status_per_series.keys()):
            if self.status_per_series[key].deleteme:
                del self.status_per_series[key]
    
    def print_patch_status(self):
        self.normalise_keys()
        for key in self.status_per_series.keys():
            series = self.status_per_series[key]
            result = "---> " + key + " -" + \
                    " ACKs: " + str(series.acks) + \
                    " NACKs: " + str(series.nacks) + \
                    " CMNT: " + str(series.warning) + \
                    " APPLIED: " + str(series.applied)
            if series.applied > 0:
                result += " ----> APPLIED, can be moved to done"
            elif series.acks >1:
                result += " ----> ACKED, waiting for APPLIED status"
            if series.warning > 0:
                result += " ----> WARNING: comments have been made: check"
            if series.nacks > 0:
                result += " ----> NACKED: check what happened"
            print(result)


def check_patch_status(subject:str):
    overall_stats = status_per_series()

    acks = 0
    applied = 0
    nack = 0
    warning = 0

    url = ktml_address + subject
    fp = urllib.request.urlopen(url)
    mybytes = fp.readlines()
    latest_version = find_highest_patch_version(mybytes)
    print("\n*** " + subject + " v" + latest_version)

    for line in mybytes:
        strline = line.decode("utf-8").upper()
        series = find_kernel_series(strline)
        if (series == ""):
            continue
      
        if latest_version == "1" or "[PATCH V" + latest_version in strline:
            if "NACK:" in strline or "NACK/" in strline:
                overall_stats.add_nack(series)
            elif "ACK:" in strline or "ACK/" in strline:
                overall_stats.add_ack(series)
            elif "CMNT:" in strline:
                overall_stats.add_warning(series)
            elif "APPLIED:" in strline:
                overall_stats.add_applied(series)
            else:
                overall_stats.add_exists(series)

    
    overall_stats.print_patch_status()

#check_patch_status("CVE-2025-21855")
#check_patch_status("CVE-2021-47269")

# By default, on myt setup, each CVE has a folder,
# so use them as a list to check
# By passing a filename tho, we can use that as a list
#   In the file, each line needs to contain a CVE name e.g. CVE-2021-47269

filename = ""
if len(sys.argv) > 1:
    filename = sys.argv[1]

if filename == "":
    dirs = os.listdir(".")
    for item in dirs:
        if os.path.isdir(item):
            check_patch_status(item)
else:
    fp = open(filename)
    for line in fp:
        check_patch_status(line)

