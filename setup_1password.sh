#!/bin/bash

# shellcheck source=/dev/null
source "$HOME/fedora_setup/utils.sh"

setup_1password() {
  if ! is_installed "op"; then
    echo -e "😱 1Password is not installed. Exiting setup... 🚶‍♂️"
    exit 1
  fi

  echo -e "\n🎉 Let's set up 1Password! 🚀"
  echo -e "\n🔐 Turn on the 1Password desktop app integration 🖥️"
  echo -e "👉 Go to: Your account -> settings > Security > Unlock using system authentication"
  echo -e "⚙️ Then, head to settings > Developer > Integrate with 1Password CLI"
  echo -e "🔑 Press Ctrl-C when you're done 🎯\n"

  # Run 1Password in the background silently (without logging info)
  echo -e "\n🛠️ Running 1Password in the background... hang tight!\n"
  1password --log 'off' >/dev/null 2>&1 &
  disown

  sleep 1

  echo -e "⏳ Press any key to continue once you've finished the setup... 👇"
  read -r -n 1 -s

  # Attempt to sign in using op CLI
  while ! op signin >/dev/null 2>&1; do
    echo -e "\n🚨 1Password sign-in failed! Please sign in manually and try again. 🤔"

    # Open the 1Password GUI for manual sign-in
    1password

    # Wait for the user to sign in manually
    echo -e "⏰ Waiting for you to sign in to 1Password... 🧑‍💻"

    # Wait until the user has successfully signed in
    while ! op signin >/dev/null 2>&1; do
      sleep 1 # Check every second if the user has signed in
    done
  done

  echo -e "\n✅ You are now signed in! Setup complete. 🎉\n"
}
