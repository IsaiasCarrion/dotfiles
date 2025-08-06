#!/bin/sh
# Obtiene el estado de Caps Lock
CAPS=$(xset q | grep "Caps Lock" | awk '{print $4}')
if [ "$CAPS" = "on" ]; then
    echo "CL" # full_text
    echo "CL" # short_text
    echo "#00B4EB" # color
else
    echo "" # full_text
    echo "" # short_text
    echo "#D8DEE9" # color
fi
