#!/bin/bash
set -e

# --- VARIABLES ---
REPO_URL="https://github.com/IsaiasCarrion/dotfiles"
DOTFILES_DIR="$HOME/.dotfiles"

# --- FUNCIONES ---
install_system_packages() {
    local packages_to_install=(
        kitty zsh fzf bat eza
        python3 python3-pip golang rustc cargo
        git gh code
        google-chrome-stable jupyter-notebook
    )

    echo "¿Quieres instalar los programas y lenguajes de desarrollo? (s/n)"
    read -r response
    if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
        echo "Instalando paquetes del sistema..."

        sudo apt update
        sudo apt install -y "${packages_to_install[@]}"

        # Instalar pipx si no está
        if ! command -v pipx &> /dev/null; then
            echo "Instalando pipx..."
            python3 -m pip install --user pipx
            python3 -m pipx ensurepath
        fi

        echo "Instalación de paquetes del sistema completada."
    else
        echo "Omitiendo la instalación de paquetes del sistema."
    fi
}

install_starship() {
    echo "¿Quieres instalar Starship? (s/n)"
    read -r response
    if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
        echo "Instalando Starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
        echo "Starship instalado."
    else
        echo "Omitiendo la instalación de Starship."
    fi
}

create_symlinks() {
    echo "¿Quieres crear los enlaces simbólicos para los dotfiles? (s/n)"
    read -r response
    if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
        echo "Creando enlaces simbólicos..."

        if [ -d "$HOME/.config" ]; then
            echo "Moviendo el directorio ~/.config existente a ~/.config.bak"
            mv "$HOME/.config" "$HOME/.config.bak"
        fi
        mkdir -p "$HOME/.config"

        ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
        ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
        ln -sf "$DOTFILES_DIR/.config/kitty" "$HOME/.config/kitty"
        ln -sf "$DOTFILES_DIR/.config/micro" "$HOME/.config/micro"

        echo "Enlaces simbólicos creados."
    else
        echo "Omitiendo la creación de enlaces simbólicos."
    fi
}

configure_zsh() {
    echo "¿Quieres configurar zsh como tu shell por defecto? (s/n)"
    read -r response
    if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
        if [ "$SHELL" != "/usr/bin/zsh" ]; then
            chsh -s /usr/bin/zsh
            echo "Zsh se ha establecido como tu shell por defecto. Reinicia tu terminal para aplicar los cambios."
        else
            echo "Zsh ya es tu shell por defecto."
        fi
    else
        echo "Omitiendo la configuración de zsh."
    fi
}

# --- LÓGICA PRINCIPAL ---
# 1. Clonar o actualizar el repositorio
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Clonando repositorio de dotfiles..."
    git clone --depth=1 "$REPO_URL" "$DOTFILES_DIR"
else
    echo "El directorio de dotfiles ya existe. Actualizando..."
    cd "$DOTFILES_DIR"
    git pull
fi

cd "$DOTFILES_DIR"

# 2. Ejecutar todas las funciones
install_system_packages
install_starship
create_symlinks
configure_zsh

echo "Configuración de dotfiles completada. ¡Disfruta!"
