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

# Lines configured by zsh-newuser-install
setopt AUTOCD BEEP EXTENDEDGLOB NOMATCH NOTIFY
# End of lines configured by zsh-newuser-install

# This is almost certainly a stupid thing to do, but I really like to be able
# to switch vi modes quickly.
KEYTIMEOUT=1

# ===========
# = History =
# ===========

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

# ================
# = Key bindings =
# ================

# Creating a new keymap, based on the predefined ‘vi insert’ keymap. I like to
# keep up to speed on my vim.
bindkey -N ekey viins
# Link the ‘ekey’ keymap to the ‘main’ keymap, and activate it
bindkey -A ekey main

# ‘up/down-line-or-search’ only utilizes the first “word” of the current line;
# I much prefer it utilizing the entire contents of the line prior to the
# insertion point (the operation of ‘history-beginning-search-forward/
# backward’). Until this is fixed, we’ll disable multi–line editing.
#bindkey '\e[A' up-line-or-search
#bindkey '\e[B' down-line-or-search
# However, we still need SINGLE_LINE_ZLE to be unset, so RPROMPT and such work
unsetopt SINGLE_LINE_ZLE
bindkey '\e[A' history-beginning-search-backward
bindkey '\e[B' history-beginning-search-forward

# ==========
# = Prompt =
# ==========

# RPS1="['%1v', '%2v', '%3v', '%4v', '%5v', '%6v', '%7v', '%8v', '%9v']" # debug
PS1=" %(?|%2F|%1F)%1(V|%1v|%(#|#|:))%(?|%2f|%1f) "


function zle-line-init {
  local STATUS=$?
  zle -K vicmd
  return $STATUS
}
zle -N   zle-line-init

function zle-keymap-select {
  local STATUS=$?
  psvar[1]="${${KEYMAP/(main|viins)/>}/vicmd/}"
  ( exit $STATUS ) # This may not seem to make sense, but it’s the only way to preserve the exit status
                   # (http://www.zsh.org/cgi-bin/mla/redirect?USERNUMBER=15796)
  zle reset-prompt
  psvar[1]=""
}
zle -N   zle-keymap-select

# ===========
# = Widgets =
# ===========

function are-widgets-working {
  echo '<yes>'
}
zle -N are-widgets-working
