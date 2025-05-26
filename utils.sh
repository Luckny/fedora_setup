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
  local array_name="$2"
  local -n arr="$array_name"

  [[ "${arr[$package]}" == "source" ]]
}

# Function to build a package from source
build_from_source() {
  local package="$1"
  local build_script="$HOME/scripts/build_scripts/${package}.sh"

  if [[ -f "$build_script" ]]; then
    echo "🔨 Building ${package} from source..."
    bash "$build_script"
  else
    echo "❌ No build script found for ${package}"
    return 1
  fi
}

# Install missing packages
install_packages() {
  local packages=("$@")
  local to_install=()
  local array_name="${FUNCNAME[1]}" # Get the name of the calling function/array

  for pkg in "${packages[@]}"; do
    # Check if it's a source package
    if is_source_package "$pkg" "$array_name"; then
      if ! is_installed "$pkg"; then
        build_from_source "$pkg"
      else
        echo "✓ ${pkg} (source) is already installed"
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
