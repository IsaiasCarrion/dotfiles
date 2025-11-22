#!/bin/bash
BASE_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
source "$BASE_DIR/library/helper.sh"

print_header "PREREQUISITOS DEL SISTEMA"

# Actualización inicial
run_command "sudo pacman -Syyu --noconfirm" "Actualizar sistema base" "yes"

# Instalación de YAY (Gestor AUR)
if command -v yay > /dev/null; then
    print_success "Yay ya está instalado."
else
    run_command "sudo pacman -S --needed --noconfirm git base-devel" "Instalar dependencias de compilación" "yes"
    run_command "git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm" "Compilar e instalar Yay" "yes"
    rm -rf /tmp/yay
fi

# Audio y Brillo
run_command "sudo pacman -S --needed --noconfirm pipewire wireplumber pamixer brightnessctl" "Instalar Stack de Audio/Brillo" "yes"

# Fuentes (Nerd Fonts)
FONTS=(
    ttf-cascadia-code-nerd
    ttf-jetbrains-mono-nerd
    ttf-fira-code
    ttf-nerd-fonts-symbols
    noto-fonts-emoji
)
run_command "sudo pacman -S --needed --noconfirm ${FONTS[*]}" "Instalar Fuentes Profesionales" "yes"

# Display Manager (SDDM)
run_command "sudo pacman -S --needed --noconfirm sddm && sudo systemctl enable sddm" "Configurar SDDM" "yes"

# Herramientas Base
run_command "sudo pacman -S --needed --noconfirm kitty nano tar unrar unzip git" "Instalar Herramientas Esenciales" "yes"

# Browser
run_command "yay -S --sudoloop --noconfirm brave-bin" "Instalar Navegador Brave" "no"
