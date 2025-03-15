#!/bin/bash

# Function to check if a package is installed via rpm OR command exists
is_installed() {
  if rpm -q "$1" &>/dev/null || command -v "$1" &>/dev/null; then
    return 0 # Installed
  else
    return 1 # Not installed
  fi
}

# Function to configure keyd
configure_keyd() {
  echo "[+] Configuring keyd (requires reboot)..."
  sudo mkdir -p /etc/keyd

  cat <<EOF | sudo tee /etc/keyd/default.conf >/dev/null
[ids]

*

[main]

# Maps capslock to escape when pressed and control when held.
capslock = overload(control, esc)
EOF

  echo "[✔] Keyd configuration applied."
}

# Install missing packages
install_packages() {
  # Check if a package list was passed, otherwise exit with an error message
  if [ "$#" -eq 0 ]; then
    echo "[✖] No package list provided."
    return 1
  fi

  packages=("$@")

  to_install=()

  for pkg in "${packages[@]}"; do
    if is_installed "$pkg"; then
      echo "[✔] $pkg is already installed."
    else
      echo "[+] $pkg is not installed. Adding to install list."
      # Special case for lazygit
      if [[ "$pkg" == "lazygit" ]]; then
        echo "[+] Enabling Copr repository for lazygit..."
        sudo dnf copr enable atim/lazygit -y || {
          echo "[✖] Failed to enable Copr repo for lazygit"
          exit 1
        }
      fi
      to_install+=("$pkg")
    fi
  done

  if [ ${#to_install[@]} -gt 0 ]; then
    echo "Installing missing packages: ${to_install[*]}..."
    sudo dnf install -y "${to_install[@]}" || {
      echo "[✖] Failed to install packages"
      exit 1
    }
    echo "[✔] Packages installed successfully."
  else
    echo "[✔] All packages are already installed."
  fi
}

stow_dotfiles() {
  # Check if a stow list was passed, otherwise exit with an error message
  if [ "$#" -eq 0 ]; then
    echo "[✖] No stow list provided."
    return 1
  fi

  stow_folders=("$@")

  echo "[+] Stowing dotfiles..."
  cd "${HOME:?}/dotfiles" || {
    echo "[✖] Failed to navigate to ~/dotfiles"
    exit 1
  }

  for folder in "${stow_folders[@]}"; do
    if [ -d "$folder" ]; then
      echo "[+] Stowing $folder..."

      # Remove existing configs safely
      if [ -d "${HOME:?}/.config/$folder" ]; then
        echo "[!] Removing existing config: ${HOME:?}/.config/$folder"
        rm -rf "${HOME:?}/.config/${folder:?}"
      fi
      if [ -d "${HOME:?}/$folder" ]; then
        echo "[!] Removing existing config: ${HOME:?}/$folder"
        rm -rf "${HOME:?}/${folder:?}"
      fi

      # Stow the folder
      stow "$folder" || {
        echo "[✖] Failed to stow $folder"
        exit 1
      }
      echo "[✔] $folder stowed."
    else
      echo "[!] Warning: ~/dotfiles/$folder does not exist. Skipping..."
    fi
  done

  cd ~ || exit 1
  echo "[✔] Dotfiles stowed."
}

# Function to clone keyd if not present
clone_keyd_into_builds() {
  echo "[+] Cloning keyd repository..."
  git clone https://github.com/rvaiya/keyd.git ~/builds/keyd || {
    echo "[✖] Failed to clone keyd repository."
    exit 1
  }
}
