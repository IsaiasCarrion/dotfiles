#!/bin/bash
# scripts/setup-paths.sh

# Variables de entorno para los otros scripts
export DOTFILES_DIR="$HOME/.dotfiles"
export SOURCE_CONFIG_DIR="$DOTFILES_DIR/dotfiles"
export VENV_DIR="$HOME/venvs"
export PROJECT_DIR="$HOME/Projects"

# Función para establecer los permisos de ejecución de los scripts de i3blocks
set_i3blocks_permissions() {
    echo "Estableciendo permisos de ejecución para los scripts de i3blocks..."

    # Busca y da permisos de ejecución a todos los scripts dentro de la carpeta
    find "$HOME/.config/i3blocks" -type f -name "*.sh" -exec chmod +x {} +

    echo "✅ Permisos de scripts de i3blocks establecidos."
}

# Llama a la función para ejecutar los comandos
set_i3blocks_permissions
