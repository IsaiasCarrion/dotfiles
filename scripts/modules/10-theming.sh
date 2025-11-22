#!/bin/bash
BASE_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
source "$BASE_DIR/library/helper.sh"

print_header "THEMING Y ESTÉTICA (System-Wide)"

# Motores de temas
run_command "sudo pacman -S --needed --noconfirm nwg-look qt5ct qt6ct kvantum" "Instalar Gestores de Temas (GTK/Qt)" "yes"

# Nota: Asumo que tienes una carpeta 'assets' en tu repo de chezmoi.
# Chezmoi ignora carpetas grandes por defecto, así que instalarlas manualmente aquí es aceptable
# SI y SOLO SI son temas globales.

ASSETS_DIR="$HOME/.local/share/chezmoi/assets" # Ajusta si tu ruta de assets es diferente

if [ -d "$ASSETS_DIR" ]; then
    # Instalar Temas GTK en /usr/share/themes (Global)
    if [ -f "$ASSETS_DIR/themes/Catppuccin-Mocha.tar.xz" ]; then
        run_command "sudo tar -xvf $ASSETS_DIR/themes/Catppuccin-Mocha.tar.xz -C /usr/share/themes/" "Instalar Tema GTK Catppuccin" "no"
    fi

    # Instalar Iconos en /usr/share/icons (Global)
    if [ -f "$ASSETS_DIR/icons/Tela-circle-dracula.tar.xz" ]; then
        run_command "sudo tar -xvf $ASSETS_DIR/icons/Tela-circle-dracula.tar.xz -C /usr/share/icons/" "Instalar Iconos Tela Circle" "no"
    fi
else
    print_error "Directorio de assets no encontrado en $ASSETS_DIR. Saltando descompresión."
fi

# Tema Kvantum
run_command "yay -S --sudoloop --noconfirm kvantum-theme-catppuccin-git" "Instalar Tema Kvantum Catppuccin" "no"
