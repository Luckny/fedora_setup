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
