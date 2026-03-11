#!/bin/bash

BASE="/home/alessio.faina@canonical.com/canonical/dkms"
DISTRO="resolute"
DSC="virtualbox_7.2.6-dfsg-3ubuntu1.dsc"

autopkgtest \
  --apt-upgrade \
  --shell-fail \
	--summary results.txt \
	--timeout-factor=3 \
  ${BASE}/tests/${DSC} \
  -- qemu --ram-size=16384 --cpus=8 ${BASE}/autopkgtests_images/autopkgtest-${DISTRO}-amd64.img
