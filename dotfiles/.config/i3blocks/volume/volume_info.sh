#!/bin/sh

# Verifica el botón del mouse
case "$BLOCK_BUTTON" in
    1)  # Clic izquierdo (mutear/desmutear)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        ;;
    4)  # Rueda hacia arriba (subir volumen)
        pactl set-sink-volume @DEFAULT_SINK@ +5%
        ;;
    5)  # Rueda hacia abajo (bajar volumen)
        pactl set-sink-volume @DEFAULT_SINK@ -5%
        ;;
esac

# Obtiene el volumen actual
VOLUME=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '/Volume/ {print $5}')

# Obtiene el estado de mute
MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '/Mute/ {print $2}')

# Formatea la salida
if [ "$MUTE" = "yes" ]; then
    echo " MUTE"
else
    echo " ${VOLUME}"
fi
