# Add cranky tools to the PATH
export PATH=$HOME/canonical/kteam-tools/cranky:$PATH
export PATH=$HOME/canonical/kteam-tools/maintscripts:$PATH

# Enable cranky bash auto-completion
source $HOME/canonical/kteam-tools/cranky/cranky-complete.bash

# If you want to use the new click-based auto-completion, uncomment the
# following instead of the above. Note that at the moment, this only
# auto-completes the subcommands but not any of their arguments or the
# valid kernel handles.
# eval "$(_CRANKY_COMPLETE=bash_source cranky)"
#

alias swm-state="~/canonical/kteam-tools/stable/swm-ls"
alias crankydocs="vim ~/canonical/kteam-tools/cranky/docs/cranking-the-kernel.md"
clean() {
	echo "== CLEANING $1 =="
	if [ -d $1 ]; then
		pushd $1
		git clean -fxd
		popd
	fi
}

c00_clean_repo() {
	clean linux-main
	clean linux-meta
	clean linux-signed
	clean linux-lrm
	clean linux-lmm
	clean linux-extra
	clean linux-extra2

	rm *_source.changes
	rm *_source.buildinfo
	rm *_source.ppa.upload
	rm *.debdiff
}

c01_create-base() {
	cranky chroot create-base "$1"
}
c02_create-session() {
	cranky chroot create-session "$1"
}
c03_check() {
	cranky chroot run "${1}" -- cat /etc/debian_chroot
}
c04_update_kteam_tools() {
	cd ~/canonical/kteam-tools && git pull && cd -
}
c05_checkout() {
	if [ $# -lt 3 ]
  then
    echo "Provide kernel and cycle"
	fi
	if [ "$2" != "--cycle" ]
	then
		echo "Use the cycle option"
	fi
	echo "Checking out $1 for cycle $3"
	cranky checkout "$1" "$2" "$3"
	version=$(eval echo "$1" | cut -d ":" -f 1)
	subversion=$(eval echo "$1" | cut -d ":" -f 2)
	folder=/home/spike/canonical/kernel/ubuntu/"$version"/linux/"$subversion"/linux-main
	cd $folder
}
c06_fix() {
	cranky fix
}
c07_rebase() {
	cranky rebase
	# Fix me and force the rebase branch to be specified
	# cranky rebase -b Ubuntu-5.15.0-164.174 --dry-run
}
c08_fix() {
	c06_fix
}
c09_open() {
	cranky open
}
c10_review() {
	echo "cranky review-master-changes"
	echo "\`\`\`"
	cranky review-master-changes
	echo "\`\`\`"
}
c10_update_configs() {
	cranky fdr clean updateconfigs
}
c10_generate_test_config() {
	ARCH=$1
	./debian/scripts/misc/annotations --arch $ARCH --flavour generic --export > TESTconfig
}
c11_linktb() {
	echo "Should link the buglink"
	#cranky link-tb
	#}
}
c12_update_dkms() {
	cranky update-dkms-versions
}
c13_close() {
	cranky close
}
c13_commit_annotations() {
	flavour=$1
	version=$2
	git add debian.$flavour/config/annotations
	git commit -m "UBUNTU [Config] : Update configs from ${version}" -m "Ignore: yes" -s
}
c14_test_in_cbd() {
	echo "cranky test in cbd"
	echo "\`\`\`"
#	git remote add cbd alessiofaina@cbd.kernel:"$1"
	git push cbd
	echo "\`\`\`"
}

c14_check_test_run() {
	ssh cbd ls $1
}

c14_results_test_run() {
	ssh cbd.kernel $1
}

c15_update_depends() {
	cranky update-dependents
#	cd linux-meta && cranky update-dependent && cd -
#	cd linux-signed && cranky update-dependent && cd -
#	cd linux-lrm && cranky update-dependent && cd -
}
c16_tags() {
	cranky tags
}
c17_verify_release() {
	echo "cranky verify release"
	echo "\`\`\`"
	cranky verify-release-ready
	echo "\`\`\`"
}
c18_pull_sources_and_build() {
	cranky pull-sources "$1" --latest
	cd linux-main
	cranky build-sources
}
c19_review() {
	cranky review *.changes
}
c20_debsign() {
	debsign *_source.changes
}
c21_push_refs() {
	cranky push-refs .
}
c22_dput_spurces() {
	REF=$1
	#REF should be something like xenial:linux-oracle
	cranky dput-sources auto ${REF}
}

cranky_check_with_upstream() {
	git range-diff HEAD..."$(git branch --remotes | grep "$(cranky shell-helper source-packages-name | head -n 1 | cut -d '-' -f 2-)" | grep "$(cat debian*/tracking-bug | cut -d ' ' -f 2 | head -n1)--auto" | awk '{print $1}' | head -n 1)"
}

deb_pull_package_from_ppa() {
	module=$1
	version=$2
	#pull-lp-source --download-only linux-restricted-modules-lowlatency 6.8.0-72.72.1
	pull-lp-source --download-only $module $version
}

swm_current_state() {
	/home/spike/canonical/kteam-tools/stable/swm-ls
}

cds_destroy_session() {
	cranky chroot destroy-session "$1"
#  NEED to remove the folder as well
#  Then find the directory listed in the schroot configuration file under
#  `/etc/schroot/chroot.d/sbuild-RELEASE-amd64` and remove this
#  directory.
#  
#  Finally, remove the file `/etc/schroot/chroot.d/sbuild-RELEASE-amd64`.
#  
#  Example:
#  
#  ```
#  $ cranky chroot destroy-session groovy:linux
#  
#  $ grep directory= /etc/schroot/chroot.d/sbuild-groovy-amd64
#  directory=/var/lib/schroot/chroots/groovy-amd64
#  
#  $ rm -rf /var/lib/schroot/chroots/groovy-amd64

}

#note
# if tis happens
# WARNING: fakeroot debian/rules autoreconstruct finalchecks failed with exit status 2: debian/scripts/misc/gen-auto-reconstruct: v6.8: tag invalid
#make: *** [debian/rules.d/1-maintainer.mk:116: autoreconstruct] Error 1
# git fetch git://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/plucky tag v6.14
