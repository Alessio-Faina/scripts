#!/bin/bash

sudo virt-copy-in -a autopkgtest-resolute-amd64.img linux-image-7.0.0-3-generic_7.0.0-3.3_amd64.deb /tmp
sudo virt-copy-in -a autopkgtest-resolute-amd64.img linux-headers-7.0.0-3-generic_7.0.0-3.3_amd64.deb /tmp
sudo virt-copy-in -a autopkgtest-resolute-amd64.img linux-modules-7.0.0-3-generic_7.0.0-3.3_amd64.deb /tmp
sudo virt-copy-in -a autopkgtest-resolute-amd64.img linux-unstable-headers-7.0.0-3_7.0.0-3.3_all.deb /tmp
sudo virt-customize -a autopkgtest-resolute-amd64.img --run-command "dpkg -i /tmp/linux-modules-7.0.0-3-generic_7.0.0-3.3_amd64.deb; dpkg -i /tmp/linux-headers-7.0.0-3-generic_7.0.0-3.3_amd64.deb; dpkg -i /tmp/linux-image-7.0.0-3-generic_7.0.0-3.3_amd64.deb; dpkg -i /tmp/linux-unstable-headers-7.0.0-3_7.0.0-3.3_all.deb"
