#!/bin/bash

# Define la ruta a tu carpeta de Wallpapers
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Selecciona un wallpaper al azar de tu carpeta
WALLPAPER_PATH=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)

# Comando para establecer el wallpaper en cada monitor con su configuración
feh --no-xinerama --bg-fill "$WALLPAPER_PATH" --output HDMI-0 --rotate left --output DP-0
