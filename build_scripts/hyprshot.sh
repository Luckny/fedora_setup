#!/bin/bash

BUILD_DIR="$HOME/.local/builds"
INSTALL_DIR="$HOME/.local/bin"

# Create directories if they don't exist
mkdir -p "$BUILD_DIR"
mkdir -p "$INSTALL_DIR"

# Clone the repository if it doesn't exist
if [ ! -d "$BUILD_DIR/Hyprshot" ]; then
  echo "🔄 Cloning Hyprshot repository..."
  cd "$BUILD_DIR"
  git clone https://github.com/Gustash/hyprshot.git Hyprshot
else
  echo "📂 Hyprshot repository already exists, updating..."
  cd "$BUILD_DIR/Hyprshot"
  git pull
fi

# Create symlink and make executable
echo "🔗 Creating symlink and setting permissions..."
ln -sf "$BUILD_DIR/Hyprshot/hyprshot" "$INSTALL_DIR/hyprshot"
sudo chmod +x "$BUILD_DIR/Hyprshot/hyprshot"

echo "✅ Hyprshot installation complete!"

