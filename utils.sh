#!/bin/bash

# Function to check if a package is installed via rpm OR command exists
is_installed() {
  if rpm -q "$1" &>/dev/null || command -v "$1" &>/dev/null; then
    return 0 # Installed
  else
    return 1 # Not installed
  fi
}

# Function to check if a package needs to be built from source
is_source_package() {
  local package="$1"
  [[ "$package" == *-s ]]
}

# Function to get the base package name (remove -s suffix)
get_base_package_name() {
  local package="$1"
  echo "${package%-s}"
}

# Function to build a package from source
build_from_source() {
  local package="$1"
  local base_name=$(get_base_package_name "$package")
  local build_script="$HOME/scripts/build_scripts/${base_name}.sh"

  if [[ -f "$build_script" ]]; then
    echo "🔨 Building ${base_name} from source..."
    bash "$build_script"
  else
    echo "❌ No build script found for ${base_name}"
    return 1
  fi
}

# Install missing packages
install_packages() {
  local packages=("$@")
  local to_install=()

  for pkg in "${packages[@]}"; do
    if is_source_package "$pkg"; then
      local base_name=$(get_base_package_name "$pkg")
      if ! is_installed "$base_name"; then
        build_from_source "$pkg"
      else
        echo "✓ ${base_name} (source) is already installed"
      fi
    else
      if ! is_installed "$pkg"; then
        echo -e " ➕ New package $pkg."
        to_install+=("$pkg")
      fi
    fi
  done

  if [ ${#to_install[@]} -gt 0 ]; then
    echo -e "🚀 Installing : ${to_install[*]}..."
    sudo dnf install -y "${to_install[@]}"
  fi
}

# Function to display file content using bat or cat
display_file() {
  local file="$1"
  if is_installed "bat" &>/dev/null; then
    bat "$file"
  else
    cat "$file"
  fi
}

# Function to verify and setup Git SSH identity
verify_git_ssh() {
  local ssh_dir="$HOME/.ssh"
  local setup_needed=false

  # Check if any SSH keys exist (looking for .pub files)
  if ! ls "${ssh_dir}"/*.pub >/dev/null 2>&1; then
    echo "❓ No SSH keys found. Would you like to create one? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      setup_needed=true
    else
      echo "⚠️ Skipping SSH key setup"
      return 1
    fi
  fi

  if [[ "$setup_needed" = true ]]; then
    echo "🔑 Setting up new SSH key..."

    # Get user email for SSH key
    echo "Enter your email address for the SSH key:"
    read -r email

    # Get desired key name
    echo "Enter a name for your SSH key (default: id_ed25519):"
    read -r keyname
    keyname=${keyname:-id_ed25519}
    local key_file="$ssh_dir/$keyname"

    # Generate SSH key
    ssh-keygen -t ed25519 -C "$email" -f "$key_file"

    # Start ssh-agent and add key
    eval "$(ssh-agent -s)"
    ssh-add "$key_file"

    # Display the public key
    echo -e "\n📋 Here's your public SSH key. Add it to your Git provider (e.g., GitHub):\n"
    display_file "${key_file}.pub"

    echo -e "\n✅ SSH key setup complete!"
    return 0
  fi

  return 0
}
