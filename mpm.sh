#!/bin/bash

print_art() {
  cat <<EOF
┌─┐┌─┐┌─┐
│M││P││M│
└─┘└─┘└─┘
EOF
}

if [[ $# -eq 0 ]]; then
  echo -e "❌ No flags provided"
  exit 1
fi

clear
print_art

set -e # Exit immediately if any command fails

source "$HOME/scripts/utils.sh"
source "$HOME/scripts/packages.conf"

# Install Zsh if not installed
if ! is_installed "zsh"; then
  echo "🔧 Installing Zsh..."
  sudo dnf install -y zsh

  echo "🔄 Changing default shell to Zsh..."
  chsh -s "$(which zsh)"
fi

echo -e "🔄 Updating system...\n"
sudo dnf update -y

while [[ $# -gt 0 ]]; do
  case "$1" in
  --utils)
    install_packages "${SYSTEM_UTILS[@]}"
    exit 0
    ;;
  --dev)
    install_packages "${DEV_TOOLS[@]}"
    exit 0
    ;;
  --kernel)
    install_packages "${KERNEL[@]}"
    exit 0
    ;;
  --desktop)
    install_packages "${DESKTOP[@]}"
    exit 0
    ;;
  --ssh)
    verify_git_ssh
    exit 0
    ;;
  --lang)
    install_packages "${LANGUAGES[@]}"
    exit 0
    ;;
  *)
    echo -e "❌ Invalid flag: $1\n"
    exit 1
    ;;
  esac
done
