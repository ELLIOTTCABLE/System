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

# Bootstrap LaunchAgents
for p in "${SYSTEM_REPO:-$HOME/Library/System}"/launchd/User\ LaunchAgents/*.plist; do
   [ -e "$p" ] || continue
   glbl="$HOME/Library/LaunchAgents/${p##*/}"
   printf "Bootstrapping LaunchAgent: %s\n" "$glbl"
   sudo launchctl bootstrap "gui/$(id -u)" "$glbl" || true
done
