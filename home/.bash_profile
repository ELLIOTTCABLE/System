if test -n "$INITS"; then
  export INITS="~/.bash_profile:$INITS"
else
  export INITS="~/.bash_profile"
fi