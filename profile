if [[ $- != *i* ]] ; then
  # Shell is non-interactive.  Be done now!
  return
fi

export SYSTEM_OSX='Mac OS X'
export SYSTEM_TIGER='Mac OS X 10.4'
export SYSTEM_LEOPARD='Mac OS X 10.5'
export SYSTEM_SNOW_LEOPARD='Mac OS X 10.6'
export SYSTEM_NIX='Linux'
export SYSTEM_CENTOS='Centos'
export SYSTEM_CENTOS5='Centos 5'
export SYSTEM_FEDORA='Fedora Core'
export SYSTEM_FEDORA4='Fedora Core 4'
export SYSTEM_ARCH='Arch Linux'
export SYSTEM_UNKNOWN='Unknown'

source $HOME/.profile.local
while [[ -z $SYSTEM || $SYSTEM =~ $SYSTEM_UNKNOWN ]]; do
  echo '$SYSTEM \033[0;91mis not set!\033[m Opening $EDITOR so you can set it…'
  sleep 2
  rm $HOME/.profile.local
  cp $HOME/.files/profile.local $HOME/.profile.local
  nano $HOME/.profile.local
  source $HOME/.profile.local
done

source $HOME/.shell_colours

# fix less
export PAGER='less'
export LESS='-fXemPm?f%f .?lbLine %lb?L of %L..:$' # Set options for less command

# Editor setup
if [[ $SYSTEM =~ $SYSTEM_OSX ]]; then
  alias espresso='open -a Espresso'
  alias esp='espresso'

  alias xcode='open -a Xcode'
fi

if [[ $SYSTEM =~ $SYSTEM_OSX ]]; then
  export EDITOR='mate -w'
  export VISUAL='mate -w'
elif [[ $SYSTEM =~ $SYSTEM_NIX ]]; then
  export EDITOR='vim'
  export VISUAL='vim'
fi

if [[ $EDITOR =~ 'mate' ]]; then
  alias et='edit .'
  alias etr='mate app config lib db public spec test vendor/plugins Rakefile'
fi

alias edit=$EDITOR
alias e='edit'

export CLICOLOR='yes'

if [[ $SYSTEM =~ $SYSTEM_OSX ]]; then
  export JAVA_HOME="/System/Library/Frameworks/JavaVM.framework/Home/"
  export EC2_HOME="/usr/local/Cellar/ec2-api-tools/1.3-41620/"
fi

export EC2_PRIVATE_KEY="$(/bin/ls $HOME/.ec2/pk-*.pem)"
export EC2_CERT="$(/bin/ls $HOME/.ec2/cert-*.pem)"

alias q='exit'

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
alias ss='screen -S'
alias sls='screen -list'

# Ruby
alias ri='ri -Tf ansi'

# Rails
alias sc='./script/console'
alias ss='./script/server'
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

# Rake
alias aok='rake aok'

# Server control
alias df='df -kH'

alias grep='grep --color=auto'

if [[ $SYSTEM =~ $SYSTEM_OSX ]]; then
  alias nzb='hellanzb.py'
fi

alias tu='top -o cpu'
alias tm='top -o vsize'

# SVN
alias sco='svn co'
alias sup='svn up'
alias sci='svn ci -m'
alias saa='svn status | grep "^\?" | awk "{print \$2}" | xargs svn add'

# git
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
alias glog='g log --graph -B -M -C --find-copies-harder --decorate --source --pretty=oneline --abbrev-commit --date=relative --left-right --all'

# alternatives, using the 'stage' metaphor
alias stage='g add'
alias unstage='g reset'
alias staged='gist'
alias unstiff='giff' # unstaged diff
alias stiff='giff --cached' # staged diff
alias stiff-last='giff HEAD^ HEAD' # last commit diff

alias diff='colordiff'

if [[ $SYSTEM =~ $SYSTEM_OSX ]]; then
  alias eve="/Applications/EVE\ Online.app/Contents/MacOS/cider"
fi

export TODOFILE=$HOME/todo.markdown
if [ -f $TODOFILE ]; then
  if [[ $(cat $TODOFILE) =~ "- " ]]; then
    echo -e "${SYSTEM_COLOUR_BOLD}Todo List:${CLEAR_COLOUR}"; tput sgr0
    echo -e "${SYSTEM_COLOUR}==========${CLEAR_COLOUR}"; tput sgr0
    cat $TODOFILE
  fi
fi

if [ ! -r $HOME/.cheats ]; then
  echo "Rebuilding Cheat cache... "
  cheat sheets | egrep '^ ' | awk {'print $1'} > $HOME/.cheats
fi

# Create files as u=rwx, g=rx, o=rx
umask 022

# Make sure to update ~/.MacOSX/environment.plist as well if you edit these
PATH="$HOME/.bin:$PATH:$EC2_HOME/bin:$HOME/.gem/ruby/1.9.1/bin"
if [[ $SYSTEM =~ $SYSTEM_OSX ]]; then
  PATH="/System/Software/bin:/usr/local/bin:/usr/local/sbin:/opt/local/bin:/opt/local/sbin:$PATH:/usr/X11/bin:/usr/local/cuda/bin"
fi
export PATH

if [[ $SYSTEM =~ $SYSTEM_OSX ]]; then
  GEM_HOME="/Users/elliottcable/.gem/ruby/1.9.1"
else
  GEM_HOME="/home/elliottcable/.gem/ruby/1.9.1"
fi
export GEM_HOME

if [[ $SYSTEM =~ $SYSTEM_OSX ]]; then
  MANPATH="/opt/local/share/man:$MANPATH"
fi
export MANPATH
