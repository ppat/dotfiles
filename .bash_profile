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

