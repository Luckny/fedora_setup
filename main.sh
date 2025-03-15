#!/bin/bash

set -e # Exit immediately if any command fails

# shellcheck source=/dev/null
source "$HOME/fedora_setup/utils.sh"
# shellcheck source=/dev/null
source "$HOME/fedora_setup/git_utils.sh"

echo "Starting setup..."

# Install Zsh
if ! is_installed "zsh"; then
  echo "Installing Zsh..."
  sudo dnf install -y zsh

  # Change default shell to Zsh
  echo "Changing default shell to Zsh..."
  chsh -s "$(which zsh)"
fi

# Loop through all arguments
for arg in "$@"; do
  if [[ "$arg" == "--clone-repos" ]]; then
    if test_git_ssh_connection; then
      clone_repos
    else
      echo "Cloning skipped due to SSH setup not being completed."
    fi
    break # Once the --clone flag is found, we can stop further checks because no support for other flags yet
  fi
done

# Install required packages
install_packages "neovim" "hyprland" "kitty" "stow" "tmux" "lazygit" "waybar" "mako" "swaylock" "bat" "btop"

# Build and install keyd if not installed
if ! is_installed "keyd"; then
  echo "[+] keyd not found. Building from source..."

  mkdir -p ~/builds

  if [ -d ~/builds/keyd ] && [ -f ~/builds/keyd/Makefile ]; then
    echo "[✔] Found existing keyd source. Using it."
  else
    echo "[✖] keyd source not found. Cloning..."
    rm -rf ~/builds/keyd # Remove any incomplete or broken directory
    clone_keyd_into_builds
  fi

  cd ~/builds/keyd || {
    echo "[✖] Failed to navigate to ~/builds/keyd"
    exit 1
  }

  if make && sudo make install; then
    echo "[✔] keyd installed successfully."

    # Configure keyd
    configure_keyd
    echo "[✔] Keyd configuration applied."
  else
    echo "[✖] Failed to build/install keyd."
    exit 1
  fi

  sudo systemctl enable --now keyd || {
    echo "[✖] Failed to enable keyd"
    exit 1
  }
else
  echo "[✔] keyd is already installed."
fi

# Link .zshrc
echo "[+] Linking dotfiles/.zshrc..."
file="$HOME/.zshrc"
if [ -f "$file" ]; then
  echo "[!] Removing existing $file"
  rm "$file"
fi

ln -s ~/dotfiles/.zshrc ~/.zshrc || {
  echo "[✖] Failed to link .zshrc"
  exit 1
}
echo "[✔] .zshrc linked."

# Stow multiple dotfiles folders
stow_dotfiles "hypr" "tmux" "kitty"

echo "✅ Setup complete! A reboot is recommended."
