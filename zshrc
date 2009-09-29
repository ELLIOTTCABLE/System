if [ -f $HOME/.profile ]; then
  source $HOME/.profile
fi

# The following lines were added by compinstall

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' completions 1
zstyle ':completion:*' expand prefix suffix
zstyle ':completion:*' file-sort modification
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' glob 1
zstyle ':completion:*' group-name ''
zstyle ':completion:*' ignore-parents parent ..
zstyle ':completion:*' insert-unambiguous true
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-suffixes true
zstyle ':completion:*' matcher-list '+' '+m:{[:lower:]}={[:upper:]}' '+r:|[._-]=** r:|=**' '+'
zstyle ':completion:*' max-errors 3
zstyle ':completion:*' menu select=0
zstyle ':completion:*' original false
zstyle ':completion:*' prompt 'Corrections (%e):'
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' substitute 1
zstyle ':completion:*' verbose true
zstyle :compinstall filename '/Users/elliottcable/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# I like to keep up to speed on my vim
bindkey -v

# History should, uh, work
HISTFILE=~/.histfile
HISTSIZE=100000
SAVEHIST=25000
setopt SHARE_HISTORY # Sexier history, srsly, why wouldn’t anybody want this?
#setopt APPEND_HISTORY     # 
#setopt INC_APPEND_HISTORY # These are handled by SHARE_HISTORY
#setopt EXTENDED_HISTORY   # 
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_SPACE # Start a line with a space to prevent saving it
setopt HIST_NO_STORE # Don’t store the `history` command itself

unsetopt SINGLE_LINE_ZLE # Multiline editing!

# Lines configured by zsh-newuser-install
setopt AUTOCD BEEP EXTENDEDGLOB NOMATCH NOTIFY
# End of lines configured by zsh-newuser-install
