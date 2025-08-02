#!/bin/bash
set -e

# --- VARIABLES ---
REPO_URL="https://github.com/IsaiasCarrion/dotfiles"
DOTFILES_DIR="$HOME/.dotfiles"

# --- FUNCIONES ---
install_proprietary_packages() {
    echo "¿Quieres instalar Google Chrome y Visual Studio Code? (s/n)"
    read -r response
    if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
        echo "Configurando repositorios para Google Chrome y Visual Studio Code..."

        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
        rm packages.microsoft.gpg

        wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
        sudo sh -c 'echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'

        echo "Repositorios configurados. Ahora instalando los programas..."
        sudo apt update
        sudo apt install -y code google-chrome-stable

        echo "Instalación de Visual Studio Code y Google Chrome completada."
    else
        echo "Omitiendo la instalación de programas propietarios."
    fi
}

install_system_packages() {
    local packages_to_install=(
        wget curl gnupg
        kitty zsh fzf bat eza
        python3 python3-pip pipx
        golang rustc cargo
        git gh
        jupyter-notebook
    )

    echo "¿Quieres instalar los programas y lenguajes de desarrollo? (s/n)"
    read -r response
    if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
        echo "Instalando paquetes del sistema..."

        sudo apt update
        sudo apt install -y "${packages_to_install[@]}"

        if command -v pipx &> /dev/null; then
            python3 -m pipx ensurepath
        fi

        echo "Instalación de paquetes del sistema completada."
    else
        echo "Omitiendo la instalación de paquetes del sistema."
    fi
}

install_oh_my_zsh() {
    echo "¿Quieres instalar Oh My Zsh? (s/n)"
    read -r response
    if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
        echo "Instalando Oh My Zsh..."

        # Instala Oh My Zsh
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

        echo "Oh My Zsh instalado. Ahora se configurará tu .zshrc."
    else
        echo "Omitiendo la instalación de Oh My Zsh."
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

install_docker() {
    echo "¿Quieres instalar Docker y Docker Compose? (s/n)"
    read -r response
    if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
        echo "Instalando Docker y Docker Compose..."

        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        echo \
          "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        sudo usermod -aG docker $USER
        echo "Docker instalado. Por favor, reinicia tu terminal o cierra y vuelve a abrir tu sesión para que los permisos se apliquen."
    else
        echo "Omitiendo la instalación de Docker."
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

               if [ -f "$HOME/.zshrc" ]; then
            echo "Borrando el .zshrc existente para crear el symlink."
            rm "$HOME/.zshrc"
        fi
        ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

        if [ -f "$HOME/.gitconfig" ]; then
            echo "Borrando el .gitconfig existente para crear el symlink."
            rm "$HOME/.gitconfig"
        fi
        ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

        ln -sf "$DOTFILES_DIR/.config/kitty" "$HOME/.config/kitty"
        ln -sf "$DOTFILES_DIR/.config/micro" "$HOME/.config/micro"

        mkdir -p "$HOME/.config/rofi"
        ln -sf "$DOTFILES_DIR/.config/rofi/nord.rasi" "$HOME/.config/rofi/nord.rasi"

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
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Clonando repositorio de dotfiles..."
    git clone --depth=1 "$REPO_URL" "$DOTFILES_DIR"
else
    echo "El directorio de dotfiles ya existe. Actualizando..."
    cd "$DOTFILES_DIR"
    git pull
fi

cd "$DOTFILES_DIR"

install_system_packages
install_proprietary_packages
install_oh_my_zsh # <-- Nuevo: Instala Oh My Zsh
install_starship
install_docker
create_symlinks
configure_zsh

echo "Configuración de dotfiles completada. ¡Disfruta!"
