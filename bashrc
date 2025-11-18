# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

export NO_AT_BRIDGE=1
PATH=$PATH:/opt/android/platform-tools:/opt/android/tools/bin:/home/dladmin/bin/
export ANDROID_HOME=/opt/android
export ANDROID_NDK_ROOT=/opt/android-ndk-r16b/
export NDK=/opt/android-ndk-r16b/
export SYSROOT=$NDK/sysroot/
export BOOST=/opt/boost_1_65_1/

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

parse_git_branch() {
 git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
if [ "$color_prompt" = yes ]; then
#    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
     PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(parse_git_branch)\$ '
#   PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

eval $(thefuck --alias)

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
        source /etc/profile.d/vte.sh
fi

# Set System Locale to enable scripts handling ABI files to make sure that
# these files are not unnecessarily reordered.
export LC_ALL=C.UTF-8

# Helper to call debian/rules quickly
alias fdr="fakeroot debian/rules"

# Set shell variables so various Debian maintenance tools know your real name
# and email address to use for packages
export DEBEMAIL="alessio.faina@canonical.com"
export DEBFULLNAME="Alessio Faina"

# Set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

reboot() { echo "Don't do that, use SUDO"; }

mbox_split() {
	/home/$(whoami)/canonical/split-mbox/mbox_split.py --url $1
}

lxc_push_kernel_and_grub_modder() {
	LXC_TARGET=$1
	KERNEL=$2
	lxc file push ~/canonical/ckct/utils/boot-kernel-simple $LXC_TARGET/root/
	lxc file push $KERNEL $LXC_TARGET/root/
}

lxc_short_push_kernel_and_grub_modder() {
	SERIES=$1
	lxc file push ~/canonical/ckct/utils/boot-kernel-simple ubuntu-${SERIES}/root/
	lxc file push ${SERIES}_amd64.tar.gz ubuntu-${SERIES}/root/
}

git_find_branch_for_commit() {
	COMMIT=$1
	git name-rev $COMMIT
}

git_find_all_branches_for_commit() {
	COMMIT=$1
	git branch -a --contains $COMMIT
}

cbd_remove_build() {
	BUILD_ID=$1
	ssh cbd rm $BUILD_ID
}

cbd_get_build_log() {
	BUILD_ID=$1
	ssh cbd cat $BUILD_ID/build.log > ./log
}

cbd_get_tarball() {
	# Expects something like this alessiofaina-xenial-d34991cf60e2-glFs/amd64/
	BUILD_ID_PLUS_ARCH=$1
	DESTINATION=$2
	FLAVOUR=$(echo $BUILD_ID_PLUS_ARCH} | cut -d'-' -f2)
	ARCH=$(echo $BUILD_ID_PLUS_ARCH} | cut -d'/' -f2)
	FILENAME=${FLAVOUR}_${ARCH}.tar.gz
	echo "Writing ${FILENAME} in ${DESTINATION}"
	ssh cbd tarball ${BUILD_ID_PLUS_ARCH} > ${DESTINATION}/${FILENAME}
}

git_send_test_mailing_list() {
	git send-email --to alessio.faina@canonical.com *
}

git_format_patch() {
	git format-patch --thread --cover-letter --subject-prefix="SRU][][PATCH" --output-directory=./OUTPUT $1
}

ktml_check_patch_status() {
	cd ~/CVEs/IN_REVIEW
	~/canonical/split-mbox/check_patch_status_mailing_list.py
	cd -
}

export KTDB_ROOT_ARCHIVE_PATH="/home/$(whoami)/canonical/ktdb"
export TESTFLINGER_SERVER="https://testflinger.canonical.com"
