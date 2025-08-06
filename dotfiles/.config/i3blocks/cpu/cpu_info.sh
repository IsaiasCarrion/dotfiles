#!/bin/sh

# Obtiene la temperatura de la CPU del sensor k10temp, que es el que tu sistema usa.
# Busca la línea 'Tctl:' y extrae el valor.
TEMP=$(sensors | grep 'Tctl:' | awk '{print $2}' | cut -c 2- | sed 's/°C//')

# Obtiene el uso de la CPU.
# mpstat nos da el uso del CPU y el valor de '%idle' es el que necesitamos.
# Restamos %idle de 100 para obtener el uso total.
CPU_USAGE=$(mpstat 1 1 | awk '/Average/ {printf("%s", 100-$NF)}')

# Define el color según la temperatura (solo si TEMP tiene un valor numérico)
if [[ "$TEMP" =~ ^[0-9]+$ ]]; then
    if [ "$TEMP" -ge 80 ]; then
        COLOR="#FA1E44" # Rojo si la temperatura es 80°C o más
    elif [ "$TEMP" -ge 65 ]; then
        COLOR="#FFB400" # Naranja si la temperatura es 65°C o más
    else
        COLOR="#00B4EB" # Azul para nivel normal
    fi
else
    # Si la temperatura no es un número, usa el color por defecto
    COLOR="#00B4EB"
fi

# Imprime la salida para i3blocks
# Línea 1: full_text
echo "CPU: ${CPU_USAGE}% | +${TEMP}°C"
# Línea 2: short_text
echo "CPU: ${TEMP}°C"
# Línea 3: color
echo "$COLOR"

