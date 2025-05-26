#!/bin/bash

# Source utils for is_installed function
source "$HOME/scripts/utils.sh"

# Check if required dependencies are available
deps=(curl jq)
for i in "${deps[@]}"; do
  if ! is_installed "$i"; then
    echo "📦 Installing required dependency: $i"
    sudo dnf install -y "$i"
  fi
done

# Get latest Go version
latest_version="$(curl -s 'https://go.dev/dl/?mode=json' | jq -r '.[0].version')"

# Function to install/update Go
update_go() {
  local arch="$1"
  local os="$2"
  local go_url="https://golang.org/dl/${latest_version}.${os}-${arch}.tar.gz"

  echo "🔄 Installing/Updating Go to ${latest_version}..."

  # Download and install Go
  sudo bash -c "curl -so '/tmp/${latest_version}.${os}-${arch}.tar.gz' -L '$go_url' && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf '/tmp/${latest_version}.${os}-${arch}.tar.gz' && \
    rm '/tmp/${latest_version}.${os}-${arch}.tar.gz'"

  # Add Go to PATH if not already there
  if ! grep -q "/usr/local/go/bin" "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >>"$HOME/.zshrc"
  fi

  export PATH=$PATH:/usr/local/go/bin
  echo "✅ Go ${latest_version} installed/updated successfully!"
}

# Check current Go installation
if is_installed "go"; then
  current_version="$(/usr/local/go/bin/go version 2>/dev/null | awk '{print $3}')"

  if [[ "$current_version" == "$latest_version" ]]; then
    echo "✓ Go is already up-to-date at version ${latest_version}"
    exit 0
  else
    echo "❓ A new version of Go is available: ${latest_version} (current: ${current_version})"
    read -p "Would you like to update? (y/n): " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      case "$(uname -m)" in
      x86_64) update_go "amd64" "linux" ;;
      arm64) update_go "arm64" "linux" ;;
      armv*) update_go "armv6l" "linux" ;;
      *)
        echo "❌ Unsupported architecture: $(uname -m)"
        exit 1
        ;;
      esac
    fi
  fi
else
  echo "❓ Go is not installed. Would you like to install it? (y/n)"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    case "$(uname -m)" in
    x86_64) update_go "amd64" "linux" ;;
    arm64) update_go "arm64" "linux" ;;
    armv*) update_go "armv6l" "linux" ;;
    *)
      echo "❌ Unsupported architecture: $(uname -m)"
      exit 1
      ;;
    esac
  else
    echo "❌ Cannot proceed without Go installed"
    exit 1
  fi
fi

