#!/bin/sh

# Verifica si el comando acpi se ejecuta correctamente.
if acpi -b 2>&1 | grep -q "No support for device type"; then
    exit 0 # No hay batería, salimos sin imprimir nada.
fi

# Obtener los datos de la primera batería.
BAT_STATUS=$(acpi -b | grep "Battery 0" | awk '{print $3}' | cut -d',' -f1)
BAT_LEVEL=$(acpi -b | grep "Battery 0" | awk '{print $4}' | cut -d'%' -f1)

# Imprimir el texto completo
if [ "$BAT_STATUS" = "Charging" ]; then
    echo "⚡ $BAT_LEVEL%"
else
    echo "🔋 $BAT_LEVEL%"
fi

# Imprimir el texto corto
echo "$BAT_LEVEL%"

# Definir el color según el estado
if [ "$BAT_STATUS" = "Charging" ]; then
    echo "#D0D000" # Amarillo para cargando
elif [ "$BAT_LEVEL" -le 15 ]; then
    echo "#FA1E44" # Rojo para batería baja
else
    echo "#007872" # Verde para nivel normal
fi
