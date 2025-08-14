#!/bin/bash
# Script para asignar workspaces a monitores de forma dinámica

CONFIG_DIR="$HOME/.config/i3"
TEMP_WS_CONFIG="$CONFIG_DIR/i3-workspaces.conf"

# Elimina el archivo anterior si existe
[ -f "$TEMP_WS_CONFIG" ] && rm "$TEMP_WS_CONFIG"

# Obtiene las salidas de video conectadas
MONITORS=($(xrandr --query | grep " connected" | cut -d" " -f1))

# Asigna los workspaces 1-5 al primer monitor
if [ -n "${MONITORS[0]}" ]; then
    for i in {1..5}; do
        echo "workspace $i output ${MONITORS[0]}" >> "$TEMP_WS_CONFIG"
    done
fi

# Asigna los workspaces 6-10 al segundo monitor si existe
if [ -n "${MONITORS[1]}" ]; then
    for i in {6..10}; do
        echo "workspace $i output ${MONITORS[1]}" >> "$TEMP_WS_CONFIG"
    done
fi
