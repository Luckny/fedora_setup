#!/bin/bash

# shellcheck source=/dev/null
source "$HOME/fedora_setup/utils.sh"

install_hyprshot() {
  package_name="hyprshot"
  if is_installed "$package_name"; then
    echo -e "✅ [SUCCESS] hyprsot is already installed."
    return
  fi

  echo -e "❌ [NOT FOUND] "$package_name" not installed. Proceeding with source build..."

  mkdir -p ~/builds

  # Check if source already exists
  if [ -d ~/builds/"$package_name" ]; then
    echo -e "📂 [INFO] Found existing source. Using it."
  else
    echo -e "⚠️  [WARNING] "$package_name" source not found. Cloning repository..."
    rm -rf ~/builds/"$package_name" # Remove any incomplete or broken directory
    clone_into_builds Gustash/hyprshot "$package_name"
  fi

  # Navigate to keyd directory
  cd ~/builds/"$package_name" || {
    echo -e "❌ [ERROR] Failed to navigate to ~/builds/"$package_name". Exiting..."
    exit 1
  }

  if ln -s ~/builds/hyprshot/hyprshot $HOME/.local/bin; then
    sudo chmod +x ~/builds/hyprshot/hyprshot
    echo -e "✅ [SUCCESS] $package_name installed successfully."
  else
    echo -e "❌ [ERROR] Failed to build/install $package_name. Exiting..."
    exit 1
  fi
}
