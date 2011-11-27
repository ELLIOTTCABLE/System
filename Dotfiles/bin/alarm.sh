#!/usr/bin/env zsh
open 'spotify:user:elliottcable:starred'
osascript <<EOF
   tell application "System Events"
      set MyList to (name of every process)
   end tell
    
   tell application "System Events" to set appList to name of application processes whose frontmost is true
    
   set activeApp to item 1 of appList
   if (MyList contains "Spotify") is true then
      tell application "Spotify" to activate
      tell application "System Events"
         tell process "Spotify"
            key code 125
            key code 36
         end tell
         delay 1
         tell application "Spotify" to next track
      end tell
      tell application "System Events"
         set visible of process "Spotify" to false
      end tell
   end if
EOF
