brew services start "borders" # https://github.com/FelixKratz/JankyBorders

# Replace iTunes w/ Spotify; requires `brew install --cask notunes` from `rest.brewfile`.
# (See: <https://github.com/tombonez/noTunes>)
defaults write digital.twisted.noTunes replacement "/Applications/Spotify.app"
defaults write digital.twisted.noTunes hideIcon 1
