#!/bin/bash

# shellcheck source=/dev/null
source "$HOME/scripts/setup/utils.sh"

# Function to configure keyd
configure_keyd() {
  echo -e "\n🛠️  Configuring keyd (requires reboot)..."
  sudo mkdir -p /etc/keyd

  cat <<EOF | sudo tee /etc/keyd/default.conf >/dev/null
[ids]

*

[main]

# Maps capslock to escape when pressed and control when held.
capslock = overload(control, esc)
EOF

  echo -e "✅ [SUCCESS] Keyd configuration applied."
}

build_keyd() {
  echo -e "\n🔨 Building and installing keyd..."

  # Check if keyd is already installed
  if is_installed "keyd"; then
    echo -e "✅ [SUCCESS] Keyd is already installed."
    return 1
  fi

  echo -e "❌ [NOT FOUND] Keyd not installed. Proceeding with source build..."
  mkdir -p ~/builds

  # Check if source already exists
  if [ -d ~/builds/keyd ] && [ -f ~/builds/keyd/Makefile ]; then
    echo -e "📂 [INFO] Found existing keyd source. Using it."
  else
    echo -e "⚠️  [WARNING] Keyd source not found. Cloning repository..."
    rm -rf ~/builds/keyd # Remove any incomplete or broken directory
    clone_into_builds rvaiya/keyd.git keyd
  fi

  # Navigate to keyd directory
  cd ~/builds/keyd || {
    echo -e "❌ [ERROR] Failed to navigate to ~/builds/keyd."
    return 1
  }

  # Build and install keyd
  if make && sudo make install; then
    echo -e "✅ [SUCCESS] Keyd installed successfully."

    # Configure keyd
    configure_keyd
    echo -e "✅ [SUCCESS] Keyd configuration applied."
  else
    echo -e "❌ [ERROR] Failed to build/install keyd. Exiting..."
    return 1
  fi

  # Enable and start keyd service
  if sudo systemctl enable --now keyd; then
    echo -e "🚀 [SUCCESS] Keyd service enabled and started."
  else
    echo -e "❌ [ERROR] Failed to enable keyd service. Exiting..."
    return 1
  fi

  return 0
}
