#!/bin/bash

# --- VARIABLES ---
REPO_URL="git@github.com:/dotfiles.git" # Cambia esto a la URL de tu repositorio
DOTFILES_DIR="$HOME/.dotfiles"

# --- FUNCIONES ---
# Función para instalar paquetes
install_packages() {
    echo "Quieres instalar los programas y lenguajes de desarrollo? (s/n)"
    read -r response
    if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
        echo "Instalando paquetes..."

        # Actualizar el sistema
        sudo apt update

        # Programas de terminal
        sudo apt install -y kitty zsh fzf bat eza

        # Lenguajes de programación
        sudo apt install -y python3 python3-pip golang rustc cargo

        # Herramientas de desarrollo
        sudo apt install -y git gh code

        # Navegador y otros
        sudo apt install -y google-chrome-stable jupyter-notebook

        # Instalar pipx si no está
        if ! command -v pipx &> /dev/null
        then
            echo "Instalando pipx..."
            python3 -m pip install --user pipx
            python3 -m pipx ensurepath
        fi

        # Establecer zsh como shell por defecto
        if [ "$SHELL" != "/usr/bin/zsh" ]; then
            chsh -s /usr/bin/zsh
            echo "Zsh se ha establecido como tu shell por defecto. Reinicia tu terminal para aplicar los cambios."
        fi

        echo "Instalación de paquetes completada."
    else
        echo "Omitiendo la instalación de paquetes."
    fi
}

# Función para crear enlaces simbólicos
create_symlinks() {
    echo "Creando enlaces simbólicos..."

    # Respalda los archivos de configuración existentes
    if [ -d "$HOME/.config" ]; then
        mv "$HOME/.config" "$HOME/.config.bak"
    fi
    mkdir -p "$HOME/.config"

    # Enlaces para archivos directos en $HOME
    ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

    # Enlaces para los directorios en .config
    ln -sf "$DOTFILES_DIR/.config/kitty" "$HOME/.config/kitty"
    ln -sf "$DOTFILES_DIR/.config/micro" "$HOME/.config/micro"

    echo "Enlaces simbólicos creados."
}

# --- LÓGICA PRINCIPAL ---
# 1. Clonar el repositorio si no existe
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Clonando repositorio de dotfiles..."
    git clone --depth=1 "$REPO_URL" "$DOTFILES_DIR"
else
    echo "El directorio de dotfiles ya existe. Actualizando..."
    cd "$DOTFILES_DIR"
    git pull
fi

# 2. Navegar al directorio de dotfiles
cd "$DOTFILES_DIR"

# 3. Preguntar si se deben instalar los paquetes
install_packages

# 4. Crear los enlaces simbólicos
create_symlinks

echo "Configuración de dotfiles completada. ¡Disfruta!"
