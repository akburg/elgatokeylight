#!/bin/bash

# Begin looking at the system log via the steam sub-command. Using a --predicate and filtering by the correct and pull out the camera event 
log stream --predicate 'subsystem == "com.apple.cmio" and composedMessage contains "streaming for client"' | while read line; do
  
  # The camera start event has been caught and is set to 'On', turn the light on
  if echo "$line" | grep "start"; then
	
	echo "Camera has been activated, turn on the light."
		
	# Light 1 - change IP to your first lights IP
	curl --location --request PUT 'http://192.168.86.40:9123/elgato/lights' --header 'Content-Type: application/json' --data-raw '{"lights":[{"brightness":40,"temperature":162,"on":1}],"numberOfLights":1}'

	#Light 2 (remove if you only have 1 light), change IP to your second light
	curl --location --request PUT 'http://192.168.86.38:9123/elgato/lights' --header 'Content-Type: application/json' --data-raw '{"lights":[{"brightness":40,"temperature":162,"on":1}],"numberOfLights":1}'

  fi

  # If we catch a camera stop event, turn the light off.
  if echo "$line" | grep "stop"; then
	echo "Camera shut down, turn off the light."
	
	#Light 1 - set to off
	curl --location --request PUT 'http://192.168.86.40:9123/elgato/lights' --header 'Content-Type: application/json' --data-raw '{"lights":[{"brightness":40,"temperature":162,"on":0}],"numberOfLights":2}'

	#Light 2 - set to off
	curl --location --request PUT 'http://192.168.86.38:9123/elgato/lights' --header 'Content-Type: application/json' --data-raw '{"lights":[{"brightness":40,"temperature":162,"on":0}],"numberOfLights":2}'

  fi
done
