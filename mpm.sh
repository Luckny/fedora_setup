#!/bin/bash

print_art() {
  cat <<EOF
=======
EOF
}

clear
print_art

set -e # Exit immediately if any command fails

source ./utils.sh
source ./packages.conf

if [[ $# -eq 0 ]]; then
  echo -e "❌ No flags provided"
  exit 1
fi

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
  --lang)
    # Remove --lang flag
    shift
    # Collect arguments into an array and shift them from $@
    lang_args=()
    while [[ $# -gt 0 && "$1" != --* ]]; do
      lang_args+=("$1")
      shift
    done

    if [[ ${#lang_args[@]} -eq 0 ]]; then
      echo -e "❌ Error: --which language??"
      exit 1
    fi

    for pkg in "${lang_args[@]}"; do
      case "$pkg" in
      c)
        echo -e "📦 Installing C language packages...\n"
        echo -e "But not really, you need to configure this"
        ;;
      *)
        exit
        ;;
      esac
    done
    ;;
  *)
    echo -e "❌ Invalid flag: $1\n"
    exit 1
    ;;
  esac
done
