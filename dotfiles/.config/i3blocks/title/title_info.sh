#!/bin/sh
xprop -id "$(xdotool getactivewindow)" | grep "WM_NAME(STRING)" | cut -d "=" -f 2 | sed 's/"//g'
