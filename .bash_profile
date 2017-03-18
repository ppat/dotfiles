#!/bin/bash
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin:~/bin"

if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

source /usr/local/etc/bash_completion.d/git-completion.bash

COLOR="\[$(tput setaf 6)\]"
RESET="\[$(tput sgr0)\]"
GIT_PS1_SHOWDIRTYSTATE=true
export PS1="[@laptop:\w] \$(__git_ps1 \" ${COLOR}(%s)${RESET} \")\$ "

warn_if_not_set() {
  temp=$1
  value=${!temp}
  if [ -z "$value" ]; then
    echo "WARNING: $1 field has not been setup. Please setup an environment variable in your .bash_profile"
  fi
}

export GIT_HOST_LOCAL=""
warn_if_not_set GIT_HOST_LOCAL
export GIT_USER_LOCAL=""
warn_if_not_set GIT_USER_LOCAL
export GIT_EMAIL_LOCAL=""
warn_if_not_set GIT_EMAIL_LOCAL
