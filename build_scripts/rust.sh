#!/bin/bash

# Source utils for is_installed function
source "$HOME/scripts/utils.sh"

# Function to get current Rust version
get_current_version() {
  rustc --version | cut -d' ' -f2
}

# Function to install/update Rust
install_rust() {
  echo "🔄 Installing/Updating Rust..."
  
  # Download and run rustup installer
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

  # Source cargo environment
  source "$HOME/.cargo/env"

  # Show installed version
  local version=$(get_current_version)
  echo "✅ Rust ${version} installed/updated successfully!"
}

# Check if Rust is installed
if is_installed "rustc"; then
  current_version=$(get_current_version)
  echo "Rust ${current_version} is currently installed"
  
  echo "❓ Would you like to update Rust and its components? (y/n)"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    # Update using rustup
    if is_installed "rustup"; then
      echo "🔄 Updating Rust using rustup..."
      rustup update
    else
      echo "⚠️ rustup not found, performing fresh installation..."
      install_rust
    fi
  fi
else
  echo "❓ Rust is not installed. Would you like to install it? (y/n)"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    install_rust
  else
    echo "❌ Cannot proceed without Rust installed"
    exit 1
  fi
fi

# Ensure cargo environment is sourced
if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi 