#!/bin/bash
# Display usage information (for --help flag)
show_help() {
  case "$1" in
  "bltctl")
    echo -e "\n📡 Bluetooth Control Script Help:"
    echo -e "  --trust        Trust the selected Bluetooth device after pairing."
    echo -e "  <scan_time>    Set scan duration in seconds (default: 10)."
    echo -e "  --help         Display this help message."
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
