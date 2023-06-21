#!/bin/bash
script_path=$(dirname "$(realpath "$0")")

config_file="$script_path/config.sh"

# Check if the configuration file exists
if [ ! -f "$config_file" ]; then
  echo "Error: Configuration file '$config_file' not found."
  exit 1
fi

# Load the configuration file
source "$config_file"

# Validate brightness value
if (( brightness < 1 || brightness > 100 )); then
  echo "Error: Invalid brightness value in the configuration file."
  exit 1
fi

# Validate temperature value
if (( temperature < 143 || temperature > 344 )); then
  echo "Error: Invalid temperature value in the configuration file."
  exit 1
fi

# Function to turn on the lights
turn_on_lights() {
  local ip=$1
  local brightness=$2
  local temperature=$3
  
  echo -e "\nCamera is activated, turn on the lights."
  curl --location --request PUT "http://$ip:9123/elgato/lights" \
    --header 'Content-Type: application/json' \
    --data-raw "{\"lights\":[{\"brightness\":$brightness,\"temperature\":$temperature,\"on\":1}]}"
}

# Function to turn off the lights
turn_off_lights() {
  local ip=$1
  
  echo -e "\nCamera is deactivated, turn off the lights."
  curl --location --request PUT "http://$ip:9123/elgato/lights" \
    --header 'Content-Type: application/json' \
    --data-raw "{\"lights\":[{\"on\":0}]}"
}

# Turn off the lights to normalize the state
power_state=$(log show --predicate 'subsystem == "com.apple.UVCExtension" and composedMessage contains "Post PowerLog"' --last 1h | awk '/VDCAssistant_Power_State/ {state = $NF} END {print state}')
if [ "$power_state" = "Off;" ]; then
  for ip in "${ip_addresses[@]}"; do
      turn_off_lights "$ip"
  done
fi
if [ "$power_state" = "On;" ]; then
  for ip in "${ip_addresses[@]}"; do
      turn_on_lights "$ip" "$brightness" "$temperature"
  done
fi


# Begin looking at the system log via the steam sub-command.
log stream --predicate 'subsystem == "com.apple.UVCExtension" and composedMessage contains "Post PowerLog"' | while read -r line; do
  # Check if the camera start event has been caught and is set to 'On'
  if echo "$line" | grep -q "= On"; then
    for ip in "${ip_addresses[@]}"; do
      turn_on_lights "$ip" "$brightness" "$temperature"
    done
  fi

# Check if we catch a camera stop event
if echo "$line" | grep -q "= Off"; then
  # Sleep for 3 seconds
  sleep 3
  # Check if the camera is still off
  power_state=$(log show --predicate 'subsystem == "com.apple.UVCExtension" and composedMessage contains "Post PowerLog"' --last 1m | awk '/VDCAssistant_Power_State/ {state = $NF} END {print state}')

  # Camera is still off after 3 seconds
  if [ "$power_state" = "Off;" ]; then
    for ip in "${ip_addresses[@]}"; do
      turn_off_lights "$ip"
    done
  fi
fi
done
