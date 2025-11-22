#!/usr/bin/env bash
set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Iniciando instalación de Dotfiles (Modo CachyOS/Arch)...${NC}"

# 1. Instalar paquetes base necesarios
echo -e "${BLUE}📦 Instalando dependencias base...${NC}"
# --needed salta lo que ya está instalado
sudo pacman -S --needed --noconfirm git stow neovim kitty zsh starship eza bat fzf ripgrep fd xclip

# 2. Preparar directorios destino (Stow a veces se queja si no existen)
mkdir -p ~/.config

# 3. Ejecutar Stow (El enlace mágico)
echo -e "${BLUE}🔗 Enlazando configuraciones con GNU Stow...${NC}"
DOTFILES_DIR="$HOME/dotfiles"
cd "$DOTFILES_DIR"

# Lista de carpetas a ignorar
IGNORE_DIRS=(".git" ".github" "scripts" "README.md" "install.sh" "LICENSE")

# Iterar sobre cada carpeta en dotfiles
for folder in */ ; do
    app_name=$(basename "$folder")

    # Verificar si está en la lista de ignorados
    if [[ " ${IGNORE_DIRS[*]} " =~ " ${app_name} " ]]; then
        continue
    fi

    echo -e "   -> Conectando: ${GREEN}$app_name${NC}"

    # --restow: re-aplica enlaces si cambiaron
    # --target: asegura que apunte a tu Home real
    stow --restow --target="$HOME" "$app_name"
done

echo -e "${GREEN}✅ ¡Instalación completada!${NC}"
echo "💡 Nota: Reinicia tu terminal o ejecuta 'zsh' para ver los cambios."
