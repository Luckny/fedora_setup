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
# shellcheck source=/dev/null
source "$HOME/fedora_setup/setup_1password.sh"
# shellcheck source=/dev/null
source "$HOME/fedora_setup/enable_processes.sh"

echo "Starting setup..."

basic_packages_file="$HOME/fedora_setup/_basic_packages.txt"
dotfile_packages_file="$HOME/fedora_setup/_dotfile_packages.txt"
dev_packages_file="$HOME/fedora_setup/_dev_packages.txt"

first_run=true
needs_reboot=false

if "$first_run"; then
  echo -e "🚀 First run detected. Running initial setup..."
  echo -e "\t Dont forget to set first_run=false in main.sh"
fi

# Install Zsh
if ! is_installed "zsh"; then
  echo "Installing Zsh..."
  sudo dnf install -y zsh

  # Change default shell to Zsh
  echo "Changing default shell to Zsh..."
  chsh -s "$(which zsh)"
fi

if [[ $# -eq 0 || "$first_run" ]]; then
  # Install required packages
  install_packages_from_file "$basic_packages_file"
fi

# Loop through all arguments
for arg in "$@"; do
  if [[ "$arg" == "--update" || "$first_run" ]]; then
    sudo dnf update -y
  fi

  if [[ "$arg" == "--clone-repos" || "$first_run" ]]; then
    if test_git_ssh_connection; then
      clone_repos
    else
      echo "Cloning skipped due to SSH setup not being completed."
    fi
  fi

  if [[ "$arg" == "--stow" || "$first_run" ]]; then
    # Install required packages
    install_packages_from_file "$dotfile_packages_file"
    stow_dotfiles "hypr" "tmux" "kitty"
  fi

  if [[ "$arg" == "--build" || "$first_run" ]]; then
    build_keyd
    needs_reboot=true
  fi

  if [[ "$arg" == "--dev" || "$first_run" ]]; then
    install_packages_from_file "$dev_packages_file"
  fi
done

if "$first_run"; then
  setup_1password
  enable_syncthing
fi

echo "✅ Setup complete!"
if $needs_reboot; then
  echo "A Reboot Is Recommended."
fi
