#!/bin/bash

GITHUB_EMAIL="luckny.simelus@gmail.com"
GITHUB_NAME="Luckny"

# Generate an SSH key if it doesn't already exist
generate_ssh_key() {
  SSH_KEY="$HOME/.ssh/id_ed25519"

  if [ ! -f "$SSH_KEY" ]; then
    echo "Generating a new SSH key..."
    ssh-keygen -t ed25519 -C "$GITHUB_EMAIL"
  else
    echo "SSH key already exists."
  fi
}

# Start ssh-agent and add the key
add_ssh_key_to_agent() {
  echo "Starting ssh-agent..."
  eval "$(ssh-agent -s)"

  echo "Adding SSH key to the agent..."
  ssh-add "$HOME/.ssh/id_ed25519"
}

# Display SSH public key
display_ssh_key() {
  echo "Your SSH public key:"
  cat "$HOME/.ssh/id_ed25519.pub"
  echo
  echo "Copy the above key and add it to GitHub: https://github.com/settings/keys"
}

# Wait for user confirmation
wait_for_github_key_addition() {
  read -r -p "Press Enter after adding the SSH key to GitHub..."
}

# Test SSH connection
test_ssh_connection() {
  echo "Testing SSH connection to GitHub..."
  ssh -T git@github.com
}

# setup git config
add_default_git_config() {
  git config --global user.name "Luckny Simelus"
  git config --global user.email "$GITHUB_NAME"
  git config --global core.editor "/usr/bin/nvim"
  git config --global pull.rebase true
  git config --global init.defaultBranch main
  git config --global push.default simple
  git config --global alias.st status
  git config --global alias.sw switch
  git config --global alias.lg "log --oneline --decorate --all --graph"
  git config --global alias
}

# Function to test SSH connection
test_git_ssh_connection() {
  echo "Testing SSH connection to GitHub..."

  output=$(ssh -T git@github.com 2>&1)

  if [[ ! "$output" == *"You've successfully authenticated"* ]]; then
    echo "SSH connection to GitHub failed."
    prompt_ssh_key_addition
    return 1 # indicate that ssh setup was not done
  else
    echo "SSH connection to GitHub successful."
    return 0 # ssh done
  fi
}

# Function to prompt the user to add an SSH key
prompt_ssh_key_addition() {
  read -r -p "GitHub SSH connection failed. Would you like to add an SSH key? (yes/no): " choice
  case "$choice" in
  yes | y)
    echo "Proceeding to generate and add SSH key..."
    generate_ssh_key
    add_ssh_key_to_agent
    display_ssh_key
    wait_for_github_key_addition
    test_ssh_connection
    add_default_git_config
    return 0 # setup successful
    ;;
  no | n)
    echo "SSH key setup skipped. You can set it up later."
    return 1 # setup skipped
    ;;
  *)
    echo "Invalid choice. Please answer with 'yes' or 'no'."
    prompt_ssh_key_addition # Recursively prompt if the user enters an invalid response
    ;;
  esac
}

clone_repos() {
  echo "[-] cloning configured repositories..."
  dotfiles="$HOME/dotfiles"
  neovim="$HOME/.config/nvim"

  if [ ! -d "$dotfiles" ]; then
    echo "[✔] dotfiles cloned to $dotfiles"
    git clone "git@github.com:Luckny/dotfiles.git" ~/
  fi

  if [ ! -d "$neovim" ]; then
    echo "[✔] Neovim cloned to $neovim"
    git clone "git@github.com:Luckny/Neovim.git" ~/.config/nvim
  fi

  echo "[✔] All repositories cloned successfully."
}
