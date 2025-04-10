#!/bin/bash

for i in {1..9}; do
  gsettings set "org.gnome.desktop.wm.keybindings" "switch-to-workspace-$i" "['<Alt>$i']"
done
