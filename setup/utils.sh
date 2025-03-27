#!/bin/bash

# Function to check if a package is installed via rpm OR command exists
is_installed() {
  if rpm -q "$1" &>/dev/null || command -v "$1" &>/dev/null; then
    return 0 # Installed
  else
    return 1 # Not installed
  fi
}

prepare_lazygit() {
  echo -e "  📦 Enabling Copr repository for lazygit..."
  if sudo dnf copr enable atim/lazygit -y; then
    echo -e "  ✅ Copr repository for lazygit enabled successfully."
  else
    echo -e "  ❌ [ERROR] Failed to enable Copr repo for lazygit. Exiting..."
    exit 1
  fi

}

prepare_1password() {
  echo -e "  📦 Enabling repository for 1password..."
  if sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc; then
    echo -e "  ✅ 1Password key added."
    if sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'; then
      echo -e "  ✅ 1Password repository added."
      sudo dnf check-update -y 1password-cli
    else
      echo -e "  ❌ [ERROR] failed to add repository for 1password. Exiting..."
      exit 1
    fi
  else
    echo -e "  ❌ [ERROR] failed to add key for 1password. Exiting..."
    exit 1
  fi
}

prepare_vscode() {
  echo -e "  📦 Enabling repository for vscode..."
  if sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc; then
    echo -e "  ✅ microsoft key added."
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null

    echo -e "  ✅ microsoft repository added."
    sudo dnf check-update -y code
  else
    echo -e "  ❌ [ERROR] failed to add key for 1password. Exiting..."
    exit 1
  fi

}

# Install missing packages
install_packages() {
  # Check if a package list was passed, otherwise exit with an error message
  if [ "$#" -eq 0 ]; then
    echo -e "❌ [ERROR] No package list provided. Exiting..."
    return 1
  fi

  packages=("$@")
  to_install=()

  echo -e "🔍 Checking for missing packages..."

  for pkg in "${packages[@]}"; do
    if ! is_installed "$pkg"; then
      echo -e "  ➕ $pkg is not installed. Adding to install list."

      # Special case for lazygit
      if [[ "$pkg" == "lazygit" ]]; then
        prepare_lazygit
      fi
      # Special case for 1password
      if [[ "$pkg" == "1password" ]]; then
        prepare_1password
      fi
      # Special case for vs-code
      if [[ "$pkg" == "code" ]]; then
        prepare_vscode
      fi

      to_install+=("$pkg")
    fi
  done

  if [ ${#to_install[@]} -gt 0 ]; then
    echo -e "🚀 Installing missing packages: ${to_install[*]}..."
    if sudo dnf install -y "${to_install[@]}"; then
      echo -e "✅ [SUCCESS] Packages installed successfully."
    else
      echo -e "❌ [ERROR] Failed to install some packages. Exiting..."
      exit 1
    fi
  else
    echo -e "✔️  All packages are already installed. No action needed."
  fi
}

install_packages_from_file() {
  # Check if a package file was passed, otherwise exit with an error message
  if [ "$#" -eq 0 ]; then
    echo -e "❌ [ERROR] No package list provided. Exiting..."
    return 1
  fi

  # package
  local packages=()

  local file="$1"

  while IFS= read -r package; do
    # Skip empty lines and comments (lines starting with #)
    if [[ -z "$package" || "$package" == \#* ]]; then
      continue
    fi
    packages+=("$package")
  done <"$file"

  install_packages "${packages[@]}"
}

prompt_reboot() {
  echo "🔄 A reboot is recommended to finalize the setup."
  echo "Options:"
  echo "  1) Update system and reboot (might take a while)"
  echo "  2) Reboot now"
  echo "  3) Do nothing"

  read -r -p "🔐 What would you like to do? (1/2/3): " choice
  case "$choice" in
  1)
    echo -e "\n⚙️ Updating system before rebooting...\n"
    sudo dnf update -y
    echo -e "\n✅ Update complete. Rebooting now...\n"
    sleep 2
    sudo reboot
    ;;
  2)
    echo -e "\n⚙️ Rebooting now...\n"
    sleep 2
    sudo reboot
    ;;
  3)
    echo -e "✅ Setup complete. Reboot later when convenient.\n"
    return 1
    ;;
  *)
    echo -e "❌ Invalid choice. Please enter 1, 2, or 3.\n"
    prompt_reboot
    ;;
  esac
}

# Function to clone keyd if not present
clone_into_builds() {
  local short_link=$1
  local name=$2

  mkdir -p ~/builds

  cd ~/builds || {
    echo -e "❌ [ERROR] Failed to navigate to ~/builds. Exiting..."
    exit 1
  }

  echo -e "\n🔄 Cloning repository..."
  if git clone https://github.com/"$short_link".git "$name"; then
    echo -e "✅ [SUCCESS] repository cloned successfully."
  else
    echo -e "❌ [ERROR] Failed to clone repository. Exiting..."
    exit 1
  fi
}
