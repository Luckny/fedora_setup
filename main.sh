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
# shellcheck source=/dev/null
source "$HOME/fedora_setup/help.sh"

echo "Starting setup..."

basic_packages_file="$HOME/fedora_setup/_basic_packages.txt"
dotfile_packages_file="$HOME/fedora_setup/_dotfile_packages.txt"
dev_packages_file="$HOME/fedora_setup/_dev_packages.txt"

run_all=false
needs_reboot=false

# Function to prompt user to run the setup
prompt_run() {
  echo -e "\n🔐 Welcome to the setup script! Would you like to run the setup with all options?"
  read -r -p "(yes/no): " choice
  case "$choice" in
  yes | y)
    echo -e "\n⚙️ Running with all options...\n"
    run_all=true
    ;;
  no | n)
    echo -e "\n❌ No flags provided. Please provide flags to specify the setup actions."
    show_help
    exit 1
    ;;
  *)
    echo -e "❌ Invalid choice. Please answer with 'yes' or 'no'.\n"
    prompt_run
    ;;
  esac
}

# If no flags are passed, show the usage message and exit
if [[ $# -eq 0 ]]; then
  prompt_run
fi

# Initial setup for the first run
if $run_all; then
  echo -e "🚀 First run detected. Running the initial setup...\n"
fi

# Install Zsh if not installed
if ! is_installed "zsh"; then
  echo "🔧 Installing Zsh..."
  sudo dnf install -y zsh

  echo "🔄 Changing default shell to Zsh..."
  chsh -s "$(which zsh)"
fi

# Main setup process if first run
if $run_all; then
  # Install required packages
  echo -e "📦 Installing base packages...\n"
  install_packages_from_file "$basic_packages_file"

  # Set up 1Password and Syncthing
  echo -e "🔑 Setting up 1Password...\n"
  setup_1password
  echo -e "🔄 Enabling Syncthing...\n"
  enable_syncthing

  # Check if SSH connection is set up before cloning
  if test_git_ssh_connection; then
    echo -e "🔁 Cloning repositories...\n"
    clone_repos
  else
    echo "🚫 Cloning skipped due to incomplete SSH setup."
  fi

  # Install dotfile packages and stow them
  echo -e "📦 Installing and stowing dotfiles...\n"
  install_packages_from_file "$dotfile_packages_file"
  stow_dotfiles "hypr" "tmux" "kitty"

  # Build keyd and prompt for reboot
  echo -e "🔧 Building Keyd...\n"
  build_keyd
  needs_reboot=true

  # Install development packages
  echo -e "📦 Installing development packages...\n"
  install_packages_from_file "$dev_packages_file"

else

  # Loop through all arguments for specific tasks
  for arg in "$@"; do
    case "$arg" in
    --help)
      show_help
      exit 0
      ;;

    --update)
      echo -e "🔄 Updating system...\n"
      sudo dnf update -y
      ;;

    --clone-repos)
      echo -e "🔁 Cloning repositories...\n"
      clone_repos
      ;;

    --stow)
      echo -e "📦 Installing and stowing dotfiles...\n"
      install_packages_from_file "$dotfile_packages_file"
      stow_dotfiles "hypr" "tmux" "kitty"
      ;;

    --build)
      echo -e "🔧 Building Keyd...\n"
      build_keyd
      needs_reboot=true
      ;;

    --dev)
      echo -e "📦 Installing development packages...\n"
      install_packages_from_file "$dev_packages_file"
      ;;

    *)
      echo -e "❌ Invalid flag: $arg\n"
      show_help
      exit 1
      ;;
    esac
  done
fi

echo -e "✅ All tasks executed successfully.\n"

if $run_all || $needs_reboot; then
  prompt_reboot
fi
