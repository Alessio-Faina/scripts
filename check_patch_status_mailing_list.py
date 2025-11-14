#! /usr/bin/env python3

# Written by Alessio Faina <alessio.faina@canonical.com>

import os
import re
import urllib.request

ktml_address:str = "http://ktml-board.kernel/archive/?q="

def find_highest_patch_version(ktml_query_result):
    version = 1
    for line in ktml_query_result:
        strline = line.decode("utf-8")
        if "[PATCH v" in strline:
            test_version = strline.split("[PATCH v")[1][:1]
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
    nack : int = 0
    warning : int = 0

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
    print("Checking " + subject + " v" + latest_version)

    for line in mybytes:
        strline = line.decode("utf-8").upper()
        series = find_kernel_series(strline)
        overall_stats.add_ack(series)
        
        if latest_version == "1" or "[PATCH v" + latest_version in strline:
            if "NACK:" in strline or "NACK/" in strline:
                nack += 1
            elif "ACK:" in strline or "ACK/" in strline:
                acks += 1
            elif "CMNT:" in strline:
                warning += 1
            elif "APPLIED:" in strline:
                applied += 1

    result = "Status: ACKs: " + str(acks) + \
            " NACKs: " + str(nack) + \
            " CMNT: " + str(warning) + \
            " APPLIED: " + str(applied)
    if applied > 0:
        result += " APPLIED, can be moved to done"
    elif acks >1:
        result += " ACKED, waiting for APPLIED status"
    if warning > 0:
        result += " WARNING: comments have been made: check"
    if nack > 0:
        result += " NACKED: check what happened"
    print(result)

check_patch_status("CVE-2025-21855")
#dirs = os.listdir(".")
#for item in dirs:
#    if os.path.isdir(item):
#        check_patch_status(item)


