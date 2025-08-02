#!/bin/sh 
file="/sys/class/backlight/intel_backlight/brightness"
actualBrightness=$(cat "$file")
newBrightness=$((actualBrightness - 20))
if [[ newBrightness -gt 5 ]]; then
	echo $newBrightness >> $file
fi
