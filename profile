if [[ $- != *i* ]] ; then
  # Shell is non-interactive.  Be done now!
  return
fi

if [ ! -f $HOME/.system ]; then
  # No system type! Can't use this bash profile.
  echo -e "** No ~/.system file! Assuming unknown **"
  sleep 2
  export SYSTEM='unknown'
  export COLOURIZE_AS='white'
else
  . $HOME/.system
fi

. $HOME/.colours
. $HOME/.prompt

export SYSTEM_OSX='Mac OS X'
export SYSTEM_TIGER='Mac OS X 10.4'
export SYSTEM_LEOPARD='Mac OS X 10.5'
export SYSTEM_NIX='Linux'
export SYSTEM_CENTOS='Centos'
export SYSTEM_CENTOS5='Centos 5'
export SYSTEM_FEDORA='Fedora Core'
export SYSTEM_FEDORA4='Fedora Core 4'
export SYSTEM_ARCH='Arch'

if [ -f $HOME/.profile.local ]; then
  . $HOME/.profile.local
fi

if [[ $SYSTEM =~ $SYSTEM_OSX ]]; then
  cd $HOME/Code/
else
  cd $HOME/
fi

# fix less
# export PAGER='less'
# export LESS='-fXemPm?f%f .?lbLine %lb?L of %L..:$' # Set options for less command

export PAGER='page'

export HISTIGNORE=''
export HISTSIZE=100000
export HISTFILESIZE=409600
if [[ $SYSTEM =~ $SYSTEM_OSX ]]; then
  export EDITOR='mate -w'
  export VISUAL='mate -w'
elif [[ $SYSTEM =~ $SYSTEM_NIX ]]; then
  export EDITOR='nano'
  export VISUAL='nano'
else
  export EDITOR='vi'
  export VISUAL='vi'
fi
export CLICOLOR='yes'
export INPUTRC='~/.inputrc'
export EVENT_NOKQUEUE=1               # for memcached
export LD_LIBRARY_PATH=/usr/local/lib # for pound

# EC2 stuff
export AWS_ACCOUNT_KEY='316177411691'
if [[ $SYSTEM =~ $SYSTEM_OSX ]]; then
  export JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Home/
fi
export EC2_HOME=$HOME/.ec2
export EC2_PRIVATE_KEY=$EC2_HOME/pk-NP5YLIXWYSZYTRFMCTMX7ZN24UEFBFEU.pem
export EC2_CERT=$EC2_HOME/cert-NP5YLIXWYSZYTRFMCTMX7ZN24UEFBFEU.pem

alias q='exit'
alias m='mate'
# Force interactives, for safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Make mkdir recursive
alias mkdir='mkdir -p'


if [[ $SYSTEM =~ $SYSTEM_OSX ]]; then
  # Real trashing for the win!
  alias trash="mv $1 ~/.Trash"
  
  alias eject='drutil eject 0'
fi

# Setup directory listing
if [[ $SYSTEM =~ $SYSTEM_NIX ]]; then
  alias ls='ls --color=always -alAFhp'
else
  alias ls='ls -alAGhp'
fi
alias cdd='cd - '                     # goto last dir cd'ed from

# Screen tools
alias sus='screen -US'
alias sls='screen -list'
alias surd='screen -aAURD'

# Ruby
# alias irb='irb --readline -r irb/completion'
alias ri='ri -Tf ansi'
alias shoes='/Applications/Shoes.app/Contents/MacOS/shoes'

# Rails
alias sc='./script/console'
alias ss='./script/server'
alias rails="/usr/bin/rails"
if [[ $SYSTEM =~ $SYSTEM_LEOPARD ]]; then
  export ERAILS="/Library/Open\ Source/Ruby\ on\ Rails/Edge"
elif [[ $SYSTEM =~ $SYSTEM_TIGER ]]; then
  export ERAILS="/Library/Rails/source/edge"
else
  export ERAILS="/usr/local/src/rails/edge"
fi
alias erails="ruby $ERAILS/railties/bin/rails"

# Merb
alias mat='merb -a thin'
alias aok='rake aok'

# Server control

# Editor setup - most only works for TextMate
alias edit=$EDITOR
alias e='edit'
if [[ $EDITOR =~ 'mate' ]]; then
  alias et='edit .'
  alias etr='mate app config lib db public spec test vendor/plugins Rakefile'
fi

alias df='df -kTh'

alias grep='grep --color=auto'
# if [[ ! $SYSTEM =~ $SYSTEM_CENTOS ]]; then
#   alias mysql='/usr/local/mysql/bin/mysql'
#   alias mysqladmin='/usr/local/mysql/bin/mysqladmin'
#   alias mysqlstart='sudo /usr/local/mysql/bin/mysqld_safe -d'
# fi
if [[ $SYSTEM =~ $SYSTEM_LEOPARD ]]; then
  alias nzb='hellanzb.py'
fi
alias tu='top -o cpu'
alias tm='top -o vsize'

# SVN
alias sco='svn co'
alias sup='svn up'
alias sci='svn ci -m'
alias saa='svn status | grep "^\?" | awk "{print \$2}" | xargs svn add'
alias sclr='find . -name .svn -print0 | xargs -0 rm -rf'
if [[ $SYSTEM =~ $SYSTEM_NIX ]]; then
  alias supbs='sudo /srv/script/control update backstage'
  alias supstage='sudo /srv/script/control update stage'
fi

## git
alias g='git'
alias gist='g status'
alias gull='g pull'
alias gush='g push'
alias gad='g add'
alias germ='g rm'
alias glean='g clean'
alias go='g co'
alias gin='g ci'
alias ganch='g branch'
alias gash='g stash'
alias giff='g --no-pager diff'

## alternatives, using the 'stage' metaphor
alias stage='g add'
alias unstage='g reset'
alias staged='gist'
alias unstiff='giff' # unstaged diff
alias stiff='giff --cached' # staged diff
alias stiff-last='giff HEAD^ HEAD' # last commit diff

alias diff='colordiff'

## ditz
alias d='ditz'
alias dodo='d todo'
alias dodo-full='d todo-full'
alias dart='d start'
alias dose='d close'
alias dause='g stop' # pause
alias digup='d drop' # give up
alias dad='d add'
alias dog='d log'
alias dicom='d comment'
alias dow='d show'

if [[ $SYSTEM =~ $SYSTEM_OSX ]]; then
  alias eve="/Applications/EVE\ Online.app/Contents/MacOS/cider"
fi

if [ -f /opt/local/etc/bash_completion ]; then
  . /opt/local/etc/bash_completion
fi

# Cache, and complete, Cheats
if [ ! -r $HOME/.cheats ]; then
        echo "Rebuilding Cheat cache... "
        cheat sheets | egrep '^ ' | awk {'print $1'} > $HOME/.cheats
fi
complete -W "$(cat $HOME/.cheats)" cheat

if [ -f /usr/local/bin/rake_completion ]; then
  complete -C /usr/local/bin/rake_completion -o default rake
fi

if [[ $SYSTEM =~ $SYSTEM_TIGER ]]; then
  alias gem="MACOSX_DEPLOYMENT_TARGET=10.4 gem"
elif [[ $SYSTEM =~ $SYSTEM_LEOPARD ]]; then
  alias gem="MACOSX_DEPLOYMENT_TARGET=10.5 gem"
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

# Create files as u=rwx, g=rx, o=rx
umask 022

shopt -s cdspell

# Tab complete for sudo
complete -cf sudo

#prevent overwriting files with cat
set -o noclobber

#stops ctrl+d from logging me out
set -o ignoreeof

#Treat undefined variables as errors
set -o nounset

# Make sure to update ~/.MacOSX/environment.plist as well if you edit these
PATH="$HOME/.bin:$PATH:$EC2_HOME/bin"
if [[ $SYSTEM =~ $SYSTEM_OSX ]]; then
  PATH="/System/Software/bin:/usr/local/bin:/usr/local/sbin:/opt/local/bin:/opt/local/sbin:$PATH:/usr/X11/bin:/usr/local/cuda/bin"
fi
export PATH

if [ -f $HOME/.profile.unprintable ]; then
  . $HOME/.profile.unprintable
fi

export DISPLAY=:0.0
export LC_CTYPE=en_US.UTF-8
