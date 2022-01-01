zplug mafredri/zsh-async,     from:github
zplug dfurnes/purer,          from:github, use:pure.zsh, as:theme

# Steal omz's termsupport for Apple Terminal. (Hacky as fuck; will have to watch to see if this
# changes.)
zplug lib/functions,          from:oh-my-zsh
zplug lib/termsupport,        from:oh-my-zsh, on:lib/functions

# N.B.: the original `zsh-syntax-highlighting` had to be loaded *last*; I don't know if this is
# still true for `fast-syntax-highlighting`
zplug zdharma-continuum/fast-syntax-highlighting, defer:3

zplug zsh-users/zsh-autosuggestions

zplug hlissner/zsh-autopair,  defer:2

zplug zuxfoucault/colored-man-pages_mod

# `fzf`'s built-in zsh support (uses star-star-tab, by default.)
zplug junegunn/fzf, use:"shell/*.zsh"

# A zsh-contrib tool for navigating *recent* directories — included in anyframe.
#zplug willghatch/zsh-cdr
#zplug mollifier/anyframe, on:willghatch/zsh-cdr, if:"(( $+commands[fzf] ))"

# `deer` is a file navigator for zsh heavily inspired by “ranger.”
zplug Vifon/deer, use:"deer"

# “k is a zsh script / plugin to make directory listings more readable, adding a bit of color and
#  some git status information on files and directories.”
zplug supercrabtree/k

# These are explicitly loaded at shenv-time; but I want zplug to install/manage them.
zplug ELLIOTTCABLE/nodenv.plugin.zsh, if:"false"
zplug ELLIOTTCABLE/rbenv.plugin.zsh, if:"false"

# NOTE: I had to call OPAM's `variables.sh` from `.shenv`, instea.
#zplug ~/.opam/opam-init,      from:local, use:init.zsh

#zplug marzocchi/zsh-notify,   if:"(( $+commands[terminal-notifier] ))"

zplug oz/safe-paste

# “This plugin toggles "sudo" before the current/previous command by pressing [ESC][ESC] in emacs
#  -mode or vi-command mode.”
zplug hcgraf/zsh-sudo

# The rest of these just offer additional completions
zplug zsh-users/zsh-completions
zplug akoenig/npm-run.plugin.zsh
zplug vasyharan/zsh-brew-services
zplug plugins/vagrant,        from:oh-my-zsh

# Available, but I haven't installed them yet:
#  - Docker
#  - Spotify-support
