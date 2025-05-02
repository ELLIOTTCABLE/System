#!/usr/bin/env bash
#               ^^ using bash because pipefaile etc aren't available in POSIX sh/dash

# TODO: Add a --zsh flag or similar, to install Sheldon plugins

# more TODOs
defaults write "com.apple.dock" "persistent-apps" -array && killall Dock
osascript -e "tell application \"System Events\" to set the autohide of the dock preferences to true"

sudo xcodebuild -license accept
# TODO: check paths to `brew` and `tmux`

cyan="$(tput setaf 6)"
reset="$(tput sgr0)"

user="$(whoami)"

puts() { printf '%s\n' "${cyan}[bootstrap.sh]${reset} $*"; }

# ---- ---- ----
# Initial script setup
# ---- ---- ----

# Change system_repoectory to $SYSTEM_REPO/Bootstrap/
cd -- "$(dirname -- "$0")/../" || exit 1
system_repo="$(pwd)"

. "$system_repo/Dotfiles/shenv"

set -eo pipefail

# ---- ---- ----
# Detailed functions
# ---- ---- ----

# Manually install build-deps of package-manager
install_package_manager_build_deps() {
   if [ -n "$IS_MAC" ]; then
      true
   else
      puts "Installing build-essential, curl, and git..."
      sudo apt-get install -y build-essential curl git
   fi
}

# Install the relevant package manager itself
install_package_manager() {
   if [ -n "$IS_MAC" ]; then
      puts "Installing Homebrew..."
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   else
      puts "NYI: Can't install package manager on non-macOS system yet..."
      exit 1
   fi
}

# Install packages that are required for the rest of the bootstrap process
install_packages_frontload() {
   if [ -n "$IS_MAC" ]; then
      puts "Installing packages required for the rest of the bootstrap process..."
      /opt/homebrew/bin/brew bundle --file="$system_repo/Bootstrap/frontload.brewfile"
   else
      puts "NYI: Can't install packages on non-macOS system yet..."
      exit 1
   fi
}

# Install the rest of the managed packages
install_packages_rest() {
   if [ -n "$IS_MAC" ]; then
      puts "Installing other packages..."
      /opt/homebrew/bin/brew bundle --file="$system_repo/Bootstrap/rest.brewfile"
   else
      puts "NYI: Can't install packages on non-macOS system yet..."
      exit 1
   fi
}

# Install runtimes
install_runtimes() {
   puts "Installing runtimes..."
   mise install
}

install_system_components() {
   if [ -n "$IS_MAC" ]; then
      puts "Installing system components ..."
      softwareupdate --install-rosetta --agree-to-license
   fi
}


# ---- ---- ----
# Begin! 🏁
# ---- ---- ----

case "${1:-FIRST_PARAM_WAS_EMPTY}" in
FIRST_PARAM_WAS_EMPTY)
   puts "Bootstrapping system..."
   puts "(\$system_repo: '$system_repo')"

   sudo -v
   install_system_components
   install_package_manager_build_deps
   install_package_manager
   install_packages_frontload

   puts "Frontload complete! Run \`$0 --split\` in a new terminal to continue."
   ;;

--split)
   if ! command -v tmux >/dev/null 2>&1; then
      puts "Sleeping until \`tmux\` is available..."

      until command -v tmux >/dev/null 2>&1; do
         printf '%s' '.'
         sleep 10
      done
   fi

   tmux -f /dev/null \
      new-session -d -s bootstrap \
      "printf '%s\n' 'Running \`$0 --rest\` in a new tmux session...'; $0 --rest; bash" \
      \; \
      split-window -h -t bootstrap \
      "printf '%s\n' 'Running \`$0 --runtimes\` in a new tmux session...'; $0 --runtimes; bash" \
      \; \
      attach-session -t bootstrap
   ;;

--runtimes)
   install_runtimes
   ;;

--rest)
   install_packages_rest
   ;;

*)
   printf '%s\n' "Usage: $0 [options]"
   printf '%s\n' ""
   printf '%s\n' "If no options are specified, the script will install the package manager and the packages required for the rest of the bootstrap process."
   printf '%s\n' ""
   printf '%s\n' "Options:"
   printf '%s\n' "  --help, -h: Show this help message"
   printf '%s\n' "  --rest: Install the rest of the packages"
   printf '%s\n' "  --runtimes: Install runtimes"
   exit 0
   ;;
esac
