# Usage:
#
#     embedded-editor-proxy.sh [ARGS]
#     embedded-editor-proxy.sh --wait [ARGS]
#     embedded-editor-proxy.sh --wait --diff $LOCAL $REMOTE
#     embedded-editor-proxy.sh --wait --merge $LOCAL $BASE $REMOTE $MERGED


unset -v wait
if [ "$1" = "--wait" ]; then
   shift
   wait=yes
fi

unset -v diff
unset -v merge
if [ "$1" = "--diff" ]; then
   shift
   diff=yes
elif [ "$1" = "--merge" ]; then
   shift
   merge=yes
fi

unset -v inside_vscode
[ "$TERM_PROGRAM" = vscode ] && inside_vscode=yes

unset -v inside_nvim
# New versions of nvim set $NVIM in :terminal.
# (See: <https://github.com/neovim/neovim/pull/11009>)
[ -n "$NVIM" ] && [ -S "$NVIM" ] \
   && inside_nvim=yes

# Old versions of nvim set $NVIM_LISTEN_ADDRESS in :terminal, including VimR
[ -n "$NVIM_LISTEN_ADDRESS" ] \
   && [ "$NVIM_LISTEN_ADDRESS" != "/tmp/nvimsocket" ] \
   && inside_nvim=yes


# Helpers
# -------
launch_vscode() {
   if [ -n "$merge" ]; then
      MERGED="$4"
      code ${wait:+--wait} "$MERGED"
   else
      [ -n "$diff" ] && set -- --diff "$@"
      code ${wait:+--wait} "$@"
   fi
}

launch_nvr() {
   if [ -n "$diff" ]; then
      nvr -d -cc split "--remote-tab${wait:+-wait}" "$@"
   elif [ -n "$merge" ]; then
      nvr -d -c "wincmd J | wincmd =" "--remote-tab${wait:+-wait}" "$@"
   else
      nvr -cc split "--remote${wait:+-wait}" "$@"
   fi
}


# Launch the editor!
# ------------------
if [ -n "$inside_vscode" ]; then
   launch_vscode "$@"

elif [ -n "$inside_nvim" ]; then
   launch_nvr "$@"

elif command -v code >/dev/null 2>&1; then
   launch_vscode "$@"
   
elif command -v vimr >/dev/null 2>&1; then
   if [ -n "$merge" ]; then
      MERGED="$4"
      vimr ${wait:+--wait} --cur-env --nvim "+Gdiffsplit!" "$MERGED"
   elif [ -n "$diff" ]; then
      "[ERROR] embedded-editor-proxy.sh"
      "Vimr diff: NYI!"
   else
      vimr ${wait:+--wait} "$@"
   fi

# elif command -v nvr >/dev/null 2>&1; then
#    launch_nvr "$@"

else
   if [ -n "$merge" ]; then
      MERGED="$4"
      nvim "+Gdiffsplit!" "$MERGED"
   elif [ -n "$diff" ]; then
      echo "[ERROR] embedded-editor-proxy.sh"
      echo "nvim diff: NYI!"
   else
      nvim "$@"
   fi
fi
