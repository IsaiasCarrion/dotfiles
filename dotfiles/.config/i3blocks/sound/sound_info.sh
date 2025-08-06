#!/bin/bash

# Este script maneja el volumen de PulseAudio de forma interactiva
# y muestra el estado en la barra de i3blocks.

# Si se ha presionado un botón del ratón, realiza una acción
case "$BLOCK_BUTTON" in
    1) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;  # Silenciar/desmutear con clic izquierdo
    3) pavucontrol ;;                               # Abrir pavucontrol con clic derecho
    4) pactl set-sink-volume @DEFAULT_SINK@ +5% ;;   # Rueda del ratón arriba
    5) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;   # Rueda del ratón abajo
esac

# Obtener el estado y el nivel de volumen
MUTED=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -oP 'Mute: \K(yes|no)')
VOLUME=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -n 1)
VOLUME_LEVEL=$(echo "$VOLUME" | sed 's/%//')

# Definir el icono y el color según el estado
if [ "$MUTED" = "yes" ]; then
    ICON=""
    COLOR="#FA1E44"
elif [ "$VOLUME_LEVEL" -eq 0 ]; then
    ICON=""
    COLOR="#FFFFFF"
elif [ "$VOLUME_LEVEL" -le 33 ]; then
    ICON=""
    COLOR="#FFFFFF"
elif [ "$VOLUME_LEVEL" -le 66 ]; then
    ICON=""
    COLOR="#FFFFFF"
else
    ICON=""
    COLOR="#FFFFFF"
fi

# Formato de salida para i3blocks
# Línea 1: full_text
echo "$ICON ${VOLUME_LEVEL}%"
# Línea 2: short_text
echo "$ICON"
# Línea 3: color
echo "$COLOR"
