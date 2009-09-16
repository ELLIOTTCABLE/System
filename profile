if [[ $- != *i* ]] ; then
  # Shell is non-interactive.  Be done now!
  return
fi

if [ ! -f $HOME/.profile.local ]; then
  # No system type! Can't use this local profile.
  echo -e "** No ~/.profile.local file! Assuming unknown system **"
  sleep 2
  export SYSTEM='unknown'
  export COLOURIZE_AS='white'
else
  . $HOME/.profile.local
fi

. $HOME/.shell_colours
