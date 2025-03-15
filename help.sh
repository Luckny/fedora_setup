#!/bin/bash
# Display usage information (for --help flag)
show_help() {
  echo -e "\n📝 Usage of the setup script:"
  echo -e "  --update        Update system packages."
  echo -e "  --clone-repos   Clone repositories via SSH (if setup)."
  echo -e "  --stow          Stow dotfiles (hypr, tmux, kitty...)."
  echo -e "  --build         Build configured packages in $HOME/builds."
  echo -e "  --dev           Install development packages."
  echo -e "  --help          Display this help message."
  echo -e "\n⚙️ Example usage: env_setup --update --clone-repos --stow\n"
}
