#!/bin/sh
# Este script obtiene el clima automáticamente de wttr.in.

# Obtiene el clima para la ubicación actual de forma automática.
WEATHER=$(curl -s "wttr.in?format=%t+%C")

# Mapeo de condiciones a íconos de Nerd Fonts.
case "$CONDITION" in
  *"Sunny"*)
    ICON=""
    ;;
  *"Clear"*)
    ICON=""
    ;;
  *"Partly cloudy"*)
    ICON=""
    ;;
  *"Cloudy"*)
    ICON=""
    ;;
  *"Overcast"*)
    ICON=""
    ;;
  *"Mist"*)
    ICON=""
    ;;
  *"Fog"*)
    ICON=""
    ;;
  *"Light rain"*)
    ICON=""
    ;;
  *"Moderate rain"*)
    ICON=""
    ;;
  *"Heavy rain"*)
    ICON=""
    ;;
  *"Showers"*)
    ICON=""
    ;;
  *"Light snow"*)
    ICON=""
    ;;
  *"Heavy snow"*)
    ICON=""
    ;;
  *"Snow"*)
    ICON=""
    ;;
  *"Thunderstorm"*)
    ICON=""
    ;;
  *"Drizzle"*)
    ICON=""
    ;;
  
esac
# Formatea la salida para i3blocks, excluyendo la ubicación para simplificar.
echo "${ICON} ${WEATHER}"

