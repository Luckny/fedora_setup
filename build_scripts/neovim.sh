#!/bin/bash

# Source utils for is_installed function
source "$HOME/scripts/utils.sh"

# Check if required dependencies are available
deps=(curl jq git make cmake gcc unzip)
for i in "${deps[@]}"; do
  if ! is_installed "$i"; then
    echo "📦 Installing required dependency: $i"
    sudo dnf install -y "$i"
  fi
done

# Function to get latest Neovim version from GitHub API
get_latest_version() {
  curl -s 'https://api.github.com/repos/neovim/neovim/releases/latest' | \
    jq -r '.tag_name'
}

# Function to get current Neovim version
get_current_version() {
  nvim --version | head -n1 | cut -d' ' -f2
}

# Function to install/update Neovim
install_neovim() {
  local version="$1"
  local BUILD_DIR="$HOME/.local/builds"
  
  echo "🔄 Installing/Updating Neovim to ${version}..."
  
  # Remove existing installation
  sudo rm -f /usr/local/bin/nvim
  sudo rm -rf /usr/local/share/nvim/

  # Create and enter build directory
  mkdir -p "$BUILD_DIR"
  cd "$BUILD_DIR"

  # Clean up any existing neovim directory
  rm -rf neovim

  # Clone and build Neovim
  echo "📥 Cloning Neovim repository..."
  git clone https://github.com/neovim/neovim.git
  cd neovim
  git checkout "$version"

  echo "🔨 Building Neovim..."
  make CMAKE_BUILD_TYPE=Release
  
  echo "📦 Installing Neovim..."
  sudo make install

  echo "✅ Neovim ${version} installed/updated successfully!"
}

# Main script
latest_version=$(get_latest_version)

if is_installed "nvim"; then
  current_version="v$(get_current_version)"
  
  if [[ "$current_version" == "$latest_version" ]]; then
    echo "✓ Neovim is already up-to-date at version ${latest_version}"
    exit 0
  else
    echo "❓ A new version of Neovim is available: ${latest_version} (current: ${current_version})"
    read -p "Would you like to update? (y/n): " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      install_neovim "$latest_version"
    fi
  fi
else
  echo "❓ Neovim is not installed. Would you like to install it? (y/n)"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    install_neovim "$latest_version"
  else
    echo "❌ Cannot proceed without Neovim installed"
    exit 1
  fi
fi 