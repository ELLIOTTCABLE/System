#!/usr/bin/env sh
# Usage:
#    BIN_DIR=~/.bin ./bootstrap-bbctl.sh --upgrade

bbctl="$(command -v bbctl)"

if [ -n "$bbctl" ]; then
   if ! [ -x "$bbctl" ]; then
      echo "ERROR: \`bbctl\` found but is not executable. Reinstalling:"
      rm -fvI "$bbctl"

   elif [ "$1" = --upgrade ]; then
      echo "Upgrading \`bbctl\` at:"
      rm -fvI "$bbctl"

      existing_dir="$(dirname "$bbctl")"

   else
      echo "\`bbctl\` already installed at: '$bbctl'"
      exit 0
   fi

else
   echo "Installing \`bbctl\`:"
fi

ubi="$(command -v ubi)"

if [ -z "$ubi" ]; then
   printf "\n"
   printf "ERROR: \`ubi\` missing. Please install it with either:\n"
   cat <<'EOF'
 $ brew install ubi
 $ TARGET="$XDG_BIN_HOME" sh -c "$(\
      curl --silent --show-error --location \
      https://raw.githubusercontent.com/houseabsolute/ubi/master/bootstrap/bootstrap-ubi.sh)"
EOF
   exit 1

else
   if ! [ -x "$ubi" ]; then
      echo "\`ubi\` found but is not executable. Please fix: '$ubi'"
      exit 1
   fi
fi

# 1. BIN_DIR if explicitly set,
# 2.
BIN_DIR="${BIN_DIR:=${existing_dir:=${XDG_BIN_HOME:-$HOME/.local/bin}}}"

ubi -p beeper/bridge-manager -i "$BIN_DIR" --rename-exe "bbctl" --verbose

echo "Installed:"
"$BIN_DIR/bbctl" --version
