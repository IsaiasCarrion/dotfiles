#!/bin/bash
BASE_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
source "$BASE_DIR/library/helper.sh"

print_header "UTILIDADES DE HYPRLAND"

# Core Utils
run_command "sudo pacman -S --needed --noconfirm waybar cliphist hypridle hyprlock hyprpaper grim slurp" "Instalar Core Utils (Waybar, Hypr*)" "yes"

# Launcher (Consistencia: Fuzzel es Wayland nativo y ligero)
run_command "sudo pacman -S --needed --noconfirm fuzzel" "Instalar Launcher (Fuzzel)" "yes"
# Si insistes con Tofi, descomenta esto y comenta Fuzzel:
# run_command "yay -S --sudoloop --noconfirm tofi" "Instalar Launcher (Tofi)" "no"

# Logout
run_command "yay -S --sudoloop --noconfirm wlogout" "Instalar Menu de Salida (wlogout)" "no"

# Screenshot avanzado
run_command "yay -S --sudoloop --noconfirm grimblast-git" "Instalar Grimblast" "no"

# Color Picker
run_command "yay -S --sudoloop --noconfirm hyprpicker" "Instalar Hyprpicker" "no"

# Montaje automático de discos
run_command "sudo pacman -S --needed --noconfirm udiskie" "Instalar Automount (Udiskie)" "yes"

print_info "NOTA: Las configuraciones (.conf) se aplicarán automáticamente con 'chezmoi apply' al final."
