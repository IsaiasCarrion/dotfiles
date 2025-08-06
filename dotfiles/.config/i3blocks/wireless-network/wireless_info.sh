#!/bin/sh

# Detecta automáticamente la interfaz de red inalámbrica activa
INTERFACE=$(ip link | awk '/state UP/ {print $2}' | sed 's/://' | grep 'w')

# Si no se encuentra una interfaz, muestra un mensaje de desconexión
if [ -z "$INTERFACE" ]; then
  echo "  Desconectado"
  echo "#c41010"
  exit
fi

# Obtiene el SSID de la red a la que estás conectado
SSID=$(iwgetid -r)

# Muestra el ícono, el SSID y el estado de la conexión
echo " ${SSID}"
echo "#D8DEE9"
