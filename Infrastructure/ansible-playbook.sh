#!/usr/bin/env dash
# Wrapper to run ansible-playbook with 1Password secret references (and other
# host-side config) resolved. Each role with secrets has a `.env` file
# containing op:// references; `op run` resolves them into env vars before
# Ansible starts.

SCRIPTPATH=$(dirname "$0")
cd "$SCRIPTPATH" || { echo "FAIL: Cannot enter '$SCRIPTPATH'"; exit ;}

scriptname="${0##*/}"
puts() { printf %s\\n "$@" ;}
pute() { printf %s\\n "~~ $*" >&2 ;}
log() { printf "[$(date -u +'%m-%d %T')] $scriptname: %s\\n" "$@" ;}
argq() { [ $# -gt 0 ] && printf "'%s' " "$@" ;}

start="$(date -u +%Y-%m-%d_%H-%M-%S)"
log_file="./logs/${scriptname}.${start}.log"

mkfifo "$HOME/.pipe.$$"
tee -a "$log_file" <"$HOME/.pipe.$$" &
exec 1>"$HOME/.pipe.$$" 2>&1
rm -f "$HOME/.pipe.$$"

# Supply defaults for inventory and playbook if not provided.
has_inventory=false
has_playbook=false
for arg; do
   case "$arg" in
      -i|--inventory|--inventory-file) has_inventory=true ;;
      -i*|--inventory=*|--inventory-file=*) has_inventory=true ;;
      *.yaml|*.yml) has_playbook=true ;;
   esac
done
$has_inventory || set -- -i hosts.yaml "$@"
$has_playbook || set -- "$@" playbook.yaml

# Build op-run + ansible-playbook command.
set -- -- ansible-playbook -v "$@"
for f in roles/*/.env; do
   [ -f "$f" ] || continue
   set -- --env-file="$f" "$@"
   log "Loading: '$f'"
done

# Example: `op run -- ansible-playbook -v -i hosts.yaml playbook.yaml --limit 'euphemios.ell.io'`
exec op run "$@"
