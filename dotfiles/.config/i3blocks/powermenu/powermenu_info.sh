#!/bin/sh

# Script para mostrar un menú de apagado/reinicio con rofi
if [ "$BLOCK_BUTTON" = "1" ]; then
    CHOICE=$(echo -e "poweroff\nreboot" | rofi -dmenu -p "Power Menu")

    case "$CHOICE" in
        poweroff)
            systemctl poweroff
            ;;
        reboot)
            systemctl reboot
            ;;
    esac
fi

echo ""
echo ""
echo "#D8DEE9"
