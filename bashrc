if test -n "$INITS"; then
  export INITS="~/.bashrc:$INITS"
else
  export INITS="~/.bashrc"
fi