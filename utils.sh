#!/bin/bash

# Function to check if a package is installed via rpm OR command exists
is_installed() {
  if rpm -q "$1" &>/dev/null || command -v "$1" &>/dev/null; then
    return 0 # Installed
  else
    return 1 # Not installed
  fi
}

# Install missing packages
install_packages() {
  packages=("$@")
  to_install=()

  for pkg in "${packages[@]}"; do
    if ! is_installed "$pkg"; then
      echo -e " ➕ New package $pkg."

      to_install+=("$pkg")
    fi
  done

  if [ ${#to_install[@]} -gt 0 ]; then
    echo -e "🚀 Installing : ${to_install[*]}..."
    sudo dnf install -y "${to_install[@]}"
  fi
}
