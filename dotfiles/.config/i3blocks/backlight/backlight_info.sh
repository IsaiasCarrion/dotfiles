#!/bin/sh
# Obtiene el brillo de la pantalla (usando xbacklight)
BRIGHTNESS=$(xbacklight -get | awk '{print int($1)}')
# Salida para i3blocks
echo " ${BRIGHTNESS}%" # full_text
echo "" # short_text
echo "#D8DEE9" # color
