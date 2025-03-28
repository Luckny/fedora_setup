#!/bin/bash

# shellcheck source=/dev/null
source "$HOME/scripts/utils/help.sh"

# Default scan time in seconds
DEFAULT_SCAN_TIME=10
TRUST_DEVICE=false

# Parse options
while [[ "$#" -gt 0 ]]; do
  case "$1" in
  --trust) TRUST_DEVICE=true ;;
  [0-9]*) SCAN_TIME="$1" ;;
  *)
    echo "⚠️ Unknown option: $1"
    show_help "bltctl"
    exit 1
    ;;
  esac
  shift
done

# Ensure scan time is valid
SCAN_TIME=${SCAN_TIME:-$DEFAULT_SCAN_TIME}
if ! [[ "$SCAN_TIME" =~ ^[0-9]+$ ]]; then
  echo "⚠️ Invalid input: Scan time must be a positive number."
  exit 1
fi

# Temporary file for scan results
TMPFILE=$(mktemp)

# Function to show progress with a message
show_progress() {
  local message="$1"
  local spin='-\|/'
  local i=0
  echo -n "$message "
  while kill -0 $2 2>/dev/null; do
    i=$(((i + 1) % 4))
    printf "\r$message ${spin:$i:1}"
    sleep 0.1
  done
  printf "\r$message ✔\n"
}

echo -e "\n🔵 Starting Bluetooth device scan for $SCAN_TIME seconds... Please wait."

# Use expect to capture interactive bluetoothctl session
expect <<EOF >"$TMPFILE" &
set timeout 20
spawn bluetoothctl
expect "# "
send "power on\r"
send "agent on\r"
send "default-agent\r"
send "scan on\r"
expect "Discovery started"
sleep $SCAN_TIME
send "scan off\r"
send "quit\r"
expect eof
EOF

show_progress "🔍 Scanning for devices..." $!

# Parse discovered devices and remove ANSI codes
devices=$(sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' "$TMPFILE" | awk '
    /\[NEW\] Device/ {
        mac = $4
        name_start = index($0, $5)
        name = substr($0, name_start)
        if (!seen[mac]++) print mac, name
    }
')

# Clean up temp file
rm "$TMPFILE"

if [ -z "$devices" ]; then
  echo -e "❌ No new devices found. Try increasing scan time.\n"
  exit 1
fi

# Let user pick a device with fzf
echo -e "\n📡 Available Bluetooth Devices:"
selected=$(echo "$devices" | fzf --height 40% --reverse --header "📌 Select Device (MAC | Name)")

if [ -z "$selected" ]; then
  echo -e "⚠️ No device selected. Exiting.\n"
  exit 1
fi

# Extract MAC address
mac=$(echo "$selected" | awk '{print $1}')
name=$(echo "$selected" | cut -d ' ' -f 2-)

echo -e "\n🔗 Selected device: $name"

# Pairing and connecting
echo -e "\n⚡ Initiating connection to: $selected"

{
  bluetoothctl remove "$mac" >/dev/null 2>&1
  echo -e "pair $mac\n" | bluetoothctl >/dev/null 2>&1
  sleep 2

  # Conditionally trust the device
  if [ "$TRUST_DEVICE" = true ]; then
    echo -e "trust $mac\n" | bluetoothctl >/dev/null 2>&1
  fi

  echo -e "connect $mac\n" | bluetoothctl >/dev/null 2>&1
} &

show_progress "🔄 Connecting to $selected..." $!

# Check connection status
connected=$(bluetoothctl info "$mac" | grep "Connected: yes")
if [ -n "$connected" ]; then
  echo -e "✅ Successfully connected to $selected! 🎉\n"
else
  echo -e "❌ Failed to connect. Try putting the device in pairing mode.\n"
fi
