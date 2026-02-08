#!/usr/bin/env sh
# shellcheck shell=dash
set -eu
cd "$(dirname "$0")/.." || exit 1

brew services start "borders" # https://github.com/FelixKratz/JankyBorders

# Replace iTunes w/ Spotify; requires `brew install --cask notunes` from `rest.brewfile`
# (See: <https://github.com/tombonez/noTunes>)
defaults write digital.twisted.noTunes replacement "/Applications/Spotify.app"
defaults write digital.twisted.noTunes hideIcon 1

# Holding Cmd+Ctrl while dragging a window will allow you to rearrange from any point
defaults write -g NSWindowShouldDragOnGesture -bool true

# Helps with Aerospace's issues w/ Mission Control
# (See: https://nikitabobko.github.io/AeroSpace/guide.html#a-note-on-mission-control)
defaults write com.apple.dock expose-group-apps -bool true

# TODO: Tweak this to not include additional paths from mise etc
sudo launchctl config user path "${PATH}"

# Create Safari SSBs
printf "Use GUI-automation to create Safari web-apps? (Do not intreact with system until complete!) [yN] "
read -r yn
case $yn in
   [Yy]*) ;;
       *) exit 1;;
esac

swift ./Scripts/create-safari-webapp.swift --verbose --yes "Perplexity" "https://www.perplexity.ai/"
swift ./Scripts/create-safari-webapp.swift --verbose --yes "Proton Mail" "https://mail.proton.me/"
swift ./Scripts/create-safari-webapp.swift --verbose --yes "FactorioLab" "https://factoriolab.github.io/"

printf "Done! Please log out and back in for all changes to take effect.\n"
