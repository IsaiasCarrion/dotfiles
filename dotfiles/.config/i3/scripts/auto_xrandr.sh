#!/bin/bash
# exec --no-startup-id xrandr --output HDMI-0 --rotate left --rate 75 --output DP-0 --primary --right-of HDMI-0 --mode 1920x1080 --rate 144
# Script para configurar monitores de forma dinámica

# Obtener los monitores conectados
MONITORS=$(xrandr --query | grep " connected" | cut -d" " -f1)
PRIMARY_MONITOR=""
SECONDARY_MONITOR=""

# Asignar los monitores a variables
for MONITOR in $MONITORS; do
    if [ -z "$PRIMARY_MONITOR" ]; then
        PRIMARY_MONITOR=$MONITOR
    else
        SECONDARY_MONITOR=$MONITOR
    fi
done

# Configurar el primer monitor
if [ -n "$PRIMARY_MONITOR" ]; then
    xrandr --output "$PRIMARY_MONITOR" --primary --auto
fi

# Configurar el segundo monitor (si existe)
if [ -n "$SECONDARY_MONITOR" ]; then
    xrandr --output "$SECONDARY_MONITOR" --auto --rotate left --right-of "$PRIMARY_MONITOR"
fi
