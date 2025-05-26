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
