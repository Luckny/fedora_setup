#!/bin/bash

enable_syncthing() {
  sudo systemctl enable syncthing@"$(whoami)".service
  sudo systemctl start syncthing@"$(whoami)".service
}
