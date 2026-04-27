#!/bin/bash

# Automatically toggle Elgato Key Light(s) when the camera activates/deactivates.
# Discovers lights via mDNS (Bonjour) so it works regardless of IP changes.

BRIGHTNESS=40
TEMPERATURE=162
CACHE_FILE="/tmp/elgato_light_urls.cache"

# Discover all Elgato lights on the network via mDNS and cache the results.
discover_lights() {
  local browse_output
  browse_output=$(dns-sd -B _elg._tcp local. 2>/dev/null &
    local pid=$!
    sleep 2
    kill $pid 2>/dev/null
  )

  local instances
  instances=$(echo "$browse_output" | awk '/Add/ {
    name = ""
    for (i=7; i<=NF; i++) name = (name ? name " " : "") $i
    print name
  }' | sort -u)

  if [ -z "$instances" ]; then
    echo "WARNING: No Elgato lights found on the network." >&2
    return 1
  fi

  > "$CACHE_FILE"
  while IFS= read -r instance; do
    local resolve_output
    resolve_output=$(dns-sd -L "$instance" _elg._tcp local. 2>/dev/null &
      local pid=$!
      sleep 2
      kill $pid 2>/dev/null
    )

    local host_port
    host_port=$(echo "$resolve_output" | grep "can be reached at" | head -1 \
      | sed 's/.*can be reached at \([^ ]*\).*/\1/')

    if [ -n "$host_port" ]; then
      echo "http://${host_port}/elgato/lights" >> "$CACHE_FILE"
    fi
  done <<< "$instances"

  local count
  count=$(wc -l < "$CACHE_FILE" | tr -d ' ')
  echo "Discovered ${count} light(s), cached in ${CACHE_FILE}"
}

# Send a command to all lights. Uses cache for instant response,
# re-discovers only if the request fails (e.g. IP changed).
control_lights() {
  local on_state=$1
  local payload="{\"lights\":[{\"brightness\":${BRIGHTNESS},\"temperature\":${TEMPERATURE},\"on\":${on_state}}],\"numberOfLights\":1}"

  while IFS= read -r url; do
    echo "  -> ${url} (on=${on_state})"
    if ! curl -s --max-time 2 --location --request PUT "$url" \
      --header 'Content-Type: application/json' \
      --data-raw "$payload" > /dev/null; then
      echo "  Request failed — re-discovering lights..."
      discover_lights
      # Retry with freshly discovered URLs
      while IFS= read -r retry_url; do
        echo "  -> ${retry_url} (on=${on_state}, retry)"
        curl -s --max-time 2 --location --request PUT "$retry_url" \
          --header 'Content-Type: application/json' \
          --data-raw "$payload" > /dev/null
      done < "$CACHE_FILE"
      return
    fi
  done < "$CACHE_FILE"
}

# Discover lights once at startup
echo "Discovering Elgato lights on the network..."
discover_lights
echo "Monitoring camera stream."

log stream --predicate 'composedMessage contains "AVFCapture"' | while read line; do

  if echo "$line" | grep -qE "AVCaptureSession_Tundra startRunning"; then
    echo "Camera has been activated, turning lights on."
    control_lights 1
  fi

  if echo "$line" | grep -qE "AVCaptureSession_Tundra stopRunning"; then
    echo "Camera shut down, turning lights off."
    control_lights 0
  fi

done
