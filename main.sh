#!/bin/bash
set -e # Exit immediately if any command fails

# shellcheck source=/dev/null
source "$HOME/fedora_setup/utils.sh"
# shellcheck source=/dev/null
source "$HOME/fedora_setup/git_utils.sh"
# shellcheck source=/dev/null
source "$HOME/fedora_setup/link_and_stow.sh"
# shellcheck source=/dev/null
source "$HOME/fedora_setup/build_keyd.sh"
echo "Starting setup..."
basic_packages_file="$HOME/fedora_setup/_basic_packages.txt"
dotfile_packages_file="$HOME/fedora_setup/_dotfile_packages.txt"
dev_packages_file="$HOME/fedora_setup/_dev_packages.txt"
needs_reboot=false

# Install Zsh
if ! is_installed "zsh"; then
  echo "Installing Zsh..."
  sudo dnf install -y zsh

  # Change default shell to Zsh
  echo "Changing default shell to Zsh..."
  chsh -s "$(which zsh)"
fi

if [ $# -eq 0 ]; then
  # Install required packages
  install_packages_from_file "$basic_packages_file"
fi

# Loop through all arguments
for arg in "$@"; do
  if [[ "$arg" == "--clone-repos" ]]; then
    if test_git_ssh_connection; then
      clone_repos
    else
      echo "Cloning skipped due to SSH setup not being completed."
    fi
  fi

  if [[ "$arg" == "--stow" ]]; then
    # Install required packages
    install_packages_from_file "$dotfile_packages_file"
    stow_dotfiles "hypr" "tmux" "kitty"
  fi

  if [[ "$arg" == "--build" ]]; then
    build_keyd
    needs_reboot=true
  fi

  if [[ "$arg" == "--dev" ]]; then
    install_packages_from_file "$dev_packages_file"
  fi
done

echo "✅ Setup complete!"
if $needs_reboot; then
  echo "A Reboot Is Recommended."
fi
