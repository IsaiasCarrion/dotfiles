#!/bin/sh
# Obtiene la memoria RAM total y usada
MEM_USED=$(free -h | awk '/Mem:/ {print $3}')
MEM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
# Salida para i3blocks
echo " ${MEM_USED}" # full_text
echo "" # short_text
echo "#D8DEE9" # color
