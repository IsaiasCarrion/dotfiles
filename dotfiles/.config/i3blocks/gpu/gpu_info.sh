#!/bin/bash
# Este script muestra el uso y la temperatura de la GPU.
# Prioriza la información de NVIDIA. Si falla, busca la de AMD.

# Ícono de chip para la GPU
ICON=""

# Intentar obtener datos de la GPU NVIDIA
if command -v nvidia-smi &> /dev/null; then
    TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)
    USAGE=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader | awk '{print $1}')
    
    if [ ! -z "$TEMP" ] && [ ! -z "$USAGE" ]; then
        echo "$ICON $USAGE% | $TEMP°C"
        exit 0
    fi
fi

# Si no se encontró información de NVIDIA, intentar con AMD (via lm-sensors)
if command -v sensors &> /dev/null; then
    # Busca la temperatura de la GPU de AMD (generalmente "Tdie" o "edge")
    # Este comando puede necesitar ser ajustado si el nombre de tu GPU es diferente
    TEMP_AMD=$(sensors | grep "amdgpu" | grep "T" | awk '{print $2}' | tr -d '+°C')

    if [ ! -z "$TEMP_AMD" ]; then
        echo "$ICON $TEMP_AMD°C"
        exit 0
    fi
fi

# Si no se encontró información de ninguna de las dos GPUs
echo "GPU: N/A"
exit 1
