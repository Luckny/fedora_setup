#!/bin/bash
set -e # Exit immediately if any command fails

# shellcheck source=/dev/null
source "$HOME/fedora_setup/utils.sh"
# shellcheck source=/dev/null
source "$HOME/fedora_setup/git_utils.sh"
# shellcheck source=/dev/null
source "$HOME/fedora_setup/link_and_stow.sh"
# shellcheck source=/dev/null
source "$HOME/fedora_setup/build_packages.sh"
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

stow_list=("hypr" "tmux" "kitty" "code" "lazygit")

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
    clone_repos_if_not_exist
  else
    echo "🚫 Cloning skipped due to incomplete SSH setup."
  fi

  # Install dotfile packages and stow them
  echo -e "📦 Installing and stowing dotfiles...\n"
  install_packages_from_file "$dotfile_packages_file"
  stow_dotfiles "${stow_list[@]}"

  # Build keyd and prompt for reboot
  echo -e "🔧 Building Keyd...\n"
  build_keyd
  needs_reboot=true

  # Install development packages
  echo -e "📦 Installing development packages...\n"
  install_packages_from_file "$dev_packages_file"

else

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --help)
      show_help
      exit 0
      ;;
    --update)
      echo -e "🔄 Updating system...\n"
      sudo dnf update -y
      shift
      ;;
    --clone-repos)
      echo -e "🔁 Cloning repositories...\n"
      clone_repos_if_not_exist
      shift
      ;;
    --stow)
      echo -e "📦 Installing and stowing dotfiles...\n"
      install_packages_from_file "$dotfile_packages_file"
      clone_repos_if_not_exist
      cd ~/dotfiles || exit
      git pull
      cd - || exit
      stow_dotfiles "${stow_list[@]}"
      shift
      ;;
    --build)
      # Remove --build flag
      shift
      # Collect build arguments into an array and shift them from $@
      build_args=()
      while [[ $# -gt 0 && "$1" != --* ]]; do
        build_args+=("$1")
        shift
      done

      if [[ ${#build_args[@]} -eq 0 ]]; then
        echo -e "❌ Error: --build requires at least one argument.\n"
        show_help
        exit 1
      fi

      for pkg in "${build_args[@]}"; do
        build_package "$pkg"
      done
      ;;
    --dev)
      echo -e "📦 Installing development packages...\n"
      install_packages_from_file "$dev_packages_file"
      shift
      ;;
    --dots)
      echo -e "📦 Installing dotfiles packages...\n"
      install_packages_from_file "$dotfile_packages_file"
      shift
      ;;
    *)
      echo -e "❌ Invalid flag: $1\n"
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
