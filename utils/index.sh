#!/bin/bash
# Display usage information (for --help flag)
show_help() {
  case "$1" in
  "bltt")
    echo -e "\n📡 Bluetooth Control Script Help:"
    echo -e "  <scan_time>    Set scan duration in seconds (default: 10)."
    echo -e "\n⚙️ Example usage: ./bluetooth_connect.sh 20 --trust\n"
    ;;

  "setup")
    echo -e "\n📝 Usage of the setup script:"
    echo -e "  --update        Update system packages."
    echo -e "  --clone-repos   Clone repositories via SSH (if setup)."
    echo -e "  --stow          Stow dotfiles (hypr, tmux, kitty...)."
    echo -e "  --build <pkg> [pkg2 pkg3 ...]   Build specified packages in $HOME/builds."
    echo -e "  --dev           Install development packages."
    echo -e "  --dots           Install dotfiles packages."
    echo -e "  --help          Display this help message."
    echo -e "\n⚙️ Example usage: env_setup --update --clone-repos --stow\n"
    ;;

  *)
    echo -e "\n❌ Unknown help topic: '$1'. Use '--help' to see available options.\n"
    ;;
  esac

}

prompt_yes_no() {
  local message="$1"

  while true; do
    echo -e "\n$message"
    # Read input with proper handling and timeout
    if ! IFS= read -r -t 60 -p "(yes/no): " choice; then
      echo -e "\n❌ No input received. Defaulting to 'no'."
      return 1
    fi

    # Clean the input: trim whitespace, remove carriage returns, lowercase
    clean_choice=$(printf "%s" "$choice" | tr -d '\r' | tr '[:upper:]' '[:lower:]' | xargs)

    case "$clean_choice" in
    yes | y)
      return 0
      ;;
    no | n)
      return 1
      ;;
    *)
      echo -e "❌ Invalid choice. Please answer with 'yes' or 'no'.\n"
      ;;
    esac
  done
}
