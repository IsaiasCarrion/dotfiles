#!/bin/bash

# Define la ubicación del archivo de datos
WEATHER_FILE="/home/$USER/.config/i3blocks/weather/forecast.xml"

# Obtiene la ciudad de tu IP usando el servicio ipapi.co
CITY_DATA=$(curl -s "https://ipapi.co/json/")
CITY_NAME=$(echo "$CITY_DATA" | jq -r '.city')

# Verifica si la ciudad se pudo obtener
if [ -z "$CITY_NAME" ]; then
  # Si no se encuentra la ciudad, usa una por defecto (puedes cambiarla)
  CITY_NAME="Buenos Aires"
fi

# Define tu clave de API de OpenWeatherMap
# ¡Asegúrate de reemplazar 'TU_CLAVE_API' con tu clave real!
API_KEY="TU_CLAVE_API"
URL="http://api.openweathermap.org/data/2.5/weather?q=$CITY_NAME&mode=xml&units=metric&appid=$API_KEY"

# Descarga el archivo forecast.xml
curl -s "$URL" > "$WEATHER_FILE"
