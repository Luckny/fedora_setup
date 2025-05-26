#!/bin/bash

# Source utils for is_installed function
source "$HOME/scripts/utils.sh"

echo "🔄 Choose installation method for lazygit:"
echo "1) Build from source using Go (latest version)"
echo "2) Install using COPR repository"
read -p "Enter your choice (1 or 2): " choice

case $choice in
  1)
    # Check if Go is installed, if not run the Go installer
    if ! is_installed "go"; then
      echo "Go is required for building from source."
      if ! bash "$HOME/scripts/build_scripts/go.sh"; then
        echo "❌ Go installation failed, cannot proceed"
        exit 1
      fi
      # Re-source PATH to get go command
      export PATH=$PATH:/usr/local/go/bin
    fi

    # Create a temporary directory for building
    BUILD_DIR="$HOME/.local/builds"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    echo "🔄 Cloning lazygit repository..."
    git clone https://github.com/jesseduffield/lazygit.git
    cd lazygit

    echo "🔨 Installing lazygit..."
    go install
    
    echo "✅ lazygit installation complete!"
    ;;
    
  2)
    echo "🔄 Enabling COPR repository..."
    sudo dnf copr enable atim/lazygit -y
    
    echo "📦 Installing lazygit..."
    sudo dnf install -y lazygit
    
    echo "✅ lazygit installation complete!"
    ;;
    
  *)
    echo "❌ Invalid choice"
    exit 1
    ;;
esac 