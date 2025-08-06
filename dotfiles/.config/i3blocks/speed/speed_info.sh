#!/bin/sh
# Detecta automáticamente la interfaz de red activa (cableada o inalámbrica)
INTERFACE=$(ip link | grep 'state UP' | awk '{print $2}' | sed 's/://' | grep -E '^e|^w')

# Si no hay interfaz activa, muestra un mensaje de desconexión
if [ -z "$INTERFACE" ]; then
    echo "睊 Desconectado"
    echo "#c41010"
    exit
fi

# Obtiene la velocidad de descarga (rx) y subida (tx) de la interfaz activa
# Nota: "today" es la sección que necesitamos del output de vnstat
SPEED=$(vnstat -i "$INTERFACE" -d 1 | grep "today" | awk '{print $3 " " $4 " / " $6 " " $7}')

# Salida para i3blocks
echo " ${SPEED}"
echo ""
echo "#D8DEE9"
