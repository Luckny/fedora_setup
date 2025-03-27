#!/bin/bash

stow_dotfiles() {
  echo -e "\n🔗 Stowing dotfiles..."

  # Link .zshrc
  echo -e "📌 [INFO] Linking dotfiles/.zshrc..."
  file="$HOME/.zshrc"

  # Check if the file exists and remove it
  if [ -f "$file" ]; then
    echo -e "⚠️  [WARNING] Removing existing $file"
    rm -f "$file"
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

      # Stow the folder
      if stow "$folder" 2>/dev/null; then
        echo -e "✅ [SUCCESS] $folder stowed."
      else
        echo -e "❌ [ERROR] Failed to stow $folder. skipping..."
      fi
    else
      echo -e "⚠️  [WARNING] ~/dotfiles/$folder does not exist. Skipping..."
    fi
  done

  cd ~ || exit 1
  echo -e "\n🎉 [DONE] Dotfiles stowed successfully."
}
