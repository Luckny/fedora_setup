#!/bin/bash

# Define the file path
LAST_TAG_FILE="$HOME/scripts/setup/nvim_tag.txt"

install_or_update_neovim() {

  # If the file exists, read the tag, otherwise initialize it to a default version
  if [ -f "$LAST_TAG_FILE" ]; then
    last_known_tag=$(cat "$LAST_TAG_FILE")
  else
    last_known_tag="0.0.0"
  fi

  # Go to the builds directory
  cd "$HOME/builds" || {
    echo "Builds directory not found!"
    exit 1
  }

  # Check if neovim directory exists, clone if not
  if [ ! -d "neovim" ]; then
    echo "Neovim repository not found. Cloning..."
    git clone https://github.com/neovim/neovim.git
    cd neovim || exit
  else
    echo "Neovim repository found. Updating tags..."
    cd neovim || exit
    git fetch --tags
  fi

  # Get the latest semantic version tag (filter out non-semver tags)
  latest_tag=$(git tag | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1)
  # Remove the "v" prefix for comparison
  latest_ver="${latest_tag#v}"

  echo "Latest tag from repository: $latest_ver"
  echo "Last known tag: $last_known_tag"

  # Compare versions using sort -V
  if [[ "$(printf '%s\n' "$last_known_tag" "$latest_ver" | sort -V | head -n1)" == "$last_known_tag" && "$last_known_tag" != "$latest_ver" ]]; then
    echo "Newer version detected. Rebuilding Neovim..."
    # Clear CMake cache
    rm -rf build/
    # Uninstall existing Neovim binaries
    sudo rm -f /usr/local/bin/nvim
    sudo rm -rf /usr/local/share/nvim
    # Build and install Neovim
    make CMAKE_BUILD_TYPE=Release
    sudo make install

    # Update the last known tag file
    echo "$latest_ver" >"$LAST_TAG_FILE"
  else
    echo "Neovim is up to date. No rebuild needed."
  fi
}
