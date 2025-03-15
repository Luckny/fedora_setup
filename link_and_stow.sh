#!/bin/bash

stow_dotfiles() {
  echo -e "\n🔗 Stowing dotfiles..."

  # Link .zshrc
  echo -e "📌 [INFO] Linking dotfiles/.zshrc..."
  file="$HOME/.zshrc"
  if [ -f "$file" ]; then
    echo -e "⚠️  [WARNING] Removing existing $file"
    rm "$file"
  fi

  if ln -s ~/dotfiles/.zshrc ~/.zshrc; then
    echo -e "✅ [SUCCESS] .zshrc linked."
  else
    echo -e "❌ [ERROR] Failed to link .zshrc. Exiting..."
    exit 1
  fi

  # Check if a stow list was provided
  if [ "$#" -eq 0 ]; then
    echo -e "❌ [ERROR] No stow list provided. Exiting..."
    return 1
  fi

  stow_folders=("$@")

  echo -e "\n📂 [INFO] Navigating to ~/dotfiles..."
  cd "${HOME:?}/dotfiles" || {
    echo -e "❌ [ERROR] Failed to navigate to ~/dotfiles. Exiting..."
    exit 1
  }

  for folder in "${stow_folders[@]}"; do
    if [ -d "$folder" ]; then
      echo -e "\n📦 [INFO] Stowing $folder..."

      # Remove existing configurations safely
      if [ -d "${HOME:?}/.config/$folder" ]; then
        echo -e "⚠️  [WARNING] Removing existing config: ${HOME:?}/.config/$folder"
        rm -rf "${HOME:?}/.config/${folder:?}"
      fi
      if [ -d "${HOME:?}/$folder" ]; then
        echo -e "⚠️  [WARNING] Removing existing config: ${HOME:?}/$folder"
        rm -rf "${HOME:?}/${folder:?}"
      fi

      # Stow the folder
      if stow "$folder"; then
        echo -e "✅ [SUCCESS] $folder stowed."
      else
        echo -e "❌ [ERROR] Failed to stow $folder. Exiting..."
        exit 1
      fi
    else
      echo -e "⚠️  [WARNING] ~/dotfiles/$folder does not exist. Skipping..."
    fi
  done

  cd ~ || exit 1
  echo -e "\n🎉 [DONE] Dotfiles stowed successfully."
}
