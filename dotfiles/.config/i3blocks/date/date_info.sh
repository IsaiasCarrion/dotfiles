#!/bin/sh
# Obtiene la fecha y hora
DATE=$(date +"%a %b %d")
TIME=$(date +"%H:%M:%S")
# Salida para i3blocks
echo " ${DATE}  ${TIME}" # full_text
echo "${TIME}" # short_text
echo "#D8DEE9" # color
