#!/bin/bash
# shellcheck source=/dev/null
source "$HOME/fedora_setup/build_keyd.sh"
source "$HOME/fedora_setup/build_hyprshot.sh"

# Function to build a package
build_package() {
  local package_name=$1
  # Loop through all arguments for specific tasks
  case "$package_name" in
  --help)
    show_help
    exit 0
    ;;

  # if is_installed "keyd"; then
  keyd)
    if build_keyd; then
      needs_reboot=true
    fi
    ;;

  hyprshot)
    install_hyprshot
    ;;

  *)
    echo -e "❌ Invalid flag: $package_name\n"
    show_help
    exit 1
    ;;
  esac

}
