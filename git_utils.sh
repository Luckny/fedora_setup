#!/bin/bash

GITHUB_EMAIL="luckny.simelus@gmail.com"
GITHUB_NAME="Luckny"

# Function to generate an SSH key
generate_ssh_key() {
  SSH_KEY="$HOME/.ssh/id_ed25519"

  if [ ! -f "$SSH_KEY" ]; then
    echo -e "\n🔑 Generating a new SSH key..."
    ssh-keygen -t ed25519 -C "$GITHUB_EMAIL"
    echo -e "✅ [SUCCESS] SSH key generated."
  else
    echo -e "✔️  SSH key already exists."
  fi
}

# Function to start ssh-agent and add the key
add_ssh_key_to_agent() {
  echo -e "\n🚀 Starting ssh-agent..."
  eval "$(ssh-agent -s)"

  echo -e "🔑 Adding SSH key to the agent..."
  ssh-add "$HOME/.ssh/id_ed25519"
  echo -e "✅ [SUCCESS] SSH key added to agent."
}

# Function to display SSH public key
display_ssh_key() {
  echo -e "\n📜 Your SSH public key:\n"
  cat "$HOME/.ssh/id_ed25519.pub"
  echo -e "\n📌 Copy the above key and add it to GitHub: https://github.com/settings/keys"
}

# Function to wait for user confirmation
wait_for_github_key_addition() {
  read -r -p "🔄 Press Enter after adding the SSH key to GitHub..."
}

# Function to test SSH connection
test_ssh_connection() {
  echo -e "\n🔍 Testing SSH connection to GitHub..."
  ssh -T git@github.com
}

# Function to test SSH connection and prompt if failed
test_git_ssh_connection() {
  echo -e "\n🔍 Testing SSH connection to GitHub..."

  output=$(ssh -T git@github.com 2>&1)

  if [[ ! "$output" == *"You've successfully authenticated"* ]]; then
    echo -e "❌ [ERROR] SSH connection to GitHub failed."
    prompt_ssh_key_addition
    return 1
  else
    echo -e "✅ [SUCCESS] SSH connection to GitHub successful."
    return 0
  fi
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

# Function to prompt the user to add an SSH key
prompt_ssh_key_addition() {
  read -r -p "🔐 GitHub SSH connection failed. Would you like to add an SSH key? (yes/no): " choice
  case "$choice" in
  yes | y)
    echo -e "\n⚙️  Proceeding to generate and add SSH key..."
    generate_ssh_key
    add_ssh_key_to_agent
    display_ssh_key
    wait_for_github_key_addition
    test_ssh_connection
    add_default_git_config
    return 0
    ;;
  no | n)
    echo -e "🚫 SSH key setup skipped. You can set it up later."
    return 1
    ;;
  *)
    echo -e "❌ Invalid choice. Please answer with 'yes' or 'no'."
    prompt_ssh_key_addition
    ;;
  esac
}

# Function to clone repositories
clone_repos() {
  echo -e "\n🔄 Cloning configured repositories..."
  dotfiles="$HOME/dotfiles"
  neovim="$HOME/.config/nvim"

  cloned_at_least_one=false

  if [ ! -d "$dotfiles" ]; then
    echo -e "📂 Cloning dotfiles to $dotfiles..."
    git clone "git@github.com:Luckny/dotfiles.git" ~/dotfiles
    cloned_at_least_one=true
  fi

  if [ ! -d "$neovim" ]; then
    echo -e "📂 Cloning Neovim config to $neovim..."
    git clone "git@github.com:Luckny/Neovim.git" ~/.config/nvim
    cloned_at_least_one=true
  fi

  if $cloned_at_least_one; then
    echo -e "✅ [SUCCESS] All repositories cloned successfully."
  else
    echo -e "✔️   No action needed."
  fi
}
