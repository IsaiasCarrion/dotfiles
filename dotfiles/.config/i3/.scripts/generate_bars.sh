#!/bin/bash

# Directorio donde se guardará el archivo de configuración temporal
CONFIG_DIR="$HOME/.config/i3"
TEMP_BAR_CONFIG="$CONFIG_DIR/i3-bars.conf"

# Elimina el archivo anterior si existe
[ -f "$TEMP_BAR_CONFIG" ] && rm "$TEMP_BAR_CONFIG"

# Obtiene los monitores conectados
MONITORS=$(xrandr --query | grep " connected" | cut -d" " -f1)

# Itera sobre los monitores y crea un bloque 'bar' para cada uno
for MONITOR in $MONITORS; do
    cat >> "$TEMP_BAR_CONFIG" << EOL
bar {
    status_command i3blocks
    position top
    font pango: Hack Nerd Font 10
    output $MONITOR
    colors {
        background #1c1c1c
        statusline #e6e6e6
        separator #4f4f4f
        focused_workspace  #8be9fd #8be9fd #1c1c1c
        active_workspace   #282a36 #282a36 #f8f8f2
        inactive_workspace #3d3d3d #3d3d3d #808080
        urgent_workspace   #ff5555 #ff5555 #ffffff
    }
}
EOL
done
