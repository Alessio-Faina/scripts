#!/bin/bash

ABI="7.3.0-6"
VERSION="${ABI}.6"

packages=(
    "linux-headers-${ABI}_${VERSION}_all.deb"
    "linux-headers-${ABI}-generic_${VERSION}_amd64.deb"
    "linux-image-${ABI}-generic_${VERSION}_amd64.deb"
    "linux-main-modules-zfs-${ABI}-generic_${VERSION}+1_amd64.deb"
    "linux-modules-${ABI}-generic_${VERSION}_amd64.deb"
		"busybox_1%3a1.38.0-3ubuntu3_amd64.deb"
		"dracut-core_112-6_amd64.deb"
		"dracut-install_112-6_amd64.deb"
		"dracut_112-6_all.deb"
		"zstd_1.5.7+dfsg-4_amd64.deb"
)

sudo virt-copy-in -a autopkgtest-stonking-amd64.img "${packages[@]}" /tmp
tmp_packages=("${packages[@]/#//tmp/}")

sudo virt-customize -a autopkgtest-stonking-amd64.img \
	--run-command "apt install -y ${tmp_packages[*]}"
