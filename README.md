# elgatokeylight
Automate Elgato Key Light Air to switch on automatically when you join a Google Meet or Zoom call (or any app that in-fact uses a camera stream on a Mac OS) and switches it off when the stream ends.

I've found it a hassle to remember to switch my lights on and off as I join various video calls throughout the day.  This bash script (works for Mac OS Monterey 12.x) monitors the Mac OS stream log and runs a curl command to activate the lights.

_Monitoring camera stream on Mac OS_

**log stream --predicate 'subsystem == "com.apple.UVCExtension" and composedMessage contains "Post PowerLog"' **

essentially monitors the stream log on Mac OS and filters out any video capture on Mac OS 12.X, for lesser versions of Mac OS, check out the good work at: https://gist.github.com/jptoto/3b2197dd652ef13bd7f3cab0f2152b19 for that.

_Turning the Engato Key Light Air On and Off_

**curl --location --request PUT 'http://<light IP address>:9123/elgato/lights' --header 'Content-Type: application/json' --data-raw '{"lights":[{"brightness":40,"temperature":162,"on":1}],"numberOfLights":1}'
**  
  
credit: https://vninja.net/2020/12/04/automating-elgato-key-lights-from-touch-bar/

You need to change the local IP address of the lights based on your local setup in the script.  The rest of the key/value pairs to configure the light are self-expalantory.

Good luck!
-Akbur Ghafoor
