source $HOME/.profile

source $HOME/.bash_prompt

export HISTIGNORE=''
export HISTSIZE=10000
export HISTFILESIZE=$HISTSIZE
export INPUTRC='~/.inputrc'

if [ -f /opt/local/etc/bash_completion ]; then
  source /opt/local/etc/bash_completion
fi

complete -W "$(cat $HOME/.cheats)" cheat

if [ -f /usr/local/bin/rake_completion ]; then
  complete -C /usr/local/bin/rake_completion -o default rake
fi

if [ -f ~/Code/src/git/contrib/completion/git-completion.bash ]; then
  source ~/Code/src/git/contrib/completion/git-completion.bash
fi


# autojump
# This shell snippet sets the prompt command and the necessary aliases
# Only excecute if the shell is bash and it is interactive
if [ $SHELL = "/bin/bash" ] && [ -n "$PS1" ]; then
  _autojump() 
  {
    local cur
    COMPREPLY=()
    unset COMP_WORDS[0] #remove "j" from the array
    cur=${COMP_WORDS[*]}
    IFS=$'\n' read -d '' -a COMPREPLY < <(autojump --completion "$cur")
    return 0
  }
  complete -F _autojump j
  alias jumpstat="autojump --stat"
  function j { new_path="$(autojump $@)";if [ -n "$new_path" ]; then echo -e "\\033[31m${new_path}\\033[0m"; echo; cd "$new_path";fi }
fi

# From http://stephencelis.com/archive/2008/6/bashfully-yours-gem-shortcuts
gemdoc() {
  local gemdir=`gem env gemdir`
  open $gemdir/doc/`$(which ls) $gemdir/doc/ | grep $1 | sort | tail -1`/rdoc/index.html
}

_gemdocomplete() {
  COMPREPLY=($(compgen -W '$(`which ls` `gem env gemdir`/doc)' -- ${COMP_WORDS[COMP_CWORD]}))
  return 0
}

# Gem RDoc, grd, grid!
alias grid="gemdoc"

complete -o default -o nospace -F _gemdocomplete gemdoc


if [[ $SYSTEM =~ $SYSTEM_OSX ]]; then
  export FIGNORE=DS_Store
fi

export LANG=en_US.UTF-8

export HISTIGNORE="&:ls:exit"

shopt -s cdspell

# Tab complete for sudo
complete -cf sudo

#prevent overwriting files with cat
set -o noclobber

#stops ctrl+d from logging me out
set -o ignoreeof

#Treat undefined variables as errors
set -o nounset

if [ -f $HOME/.bash_profile.unprintable ]; then
  source $HOME/.bash_profile.unprintable
fi
