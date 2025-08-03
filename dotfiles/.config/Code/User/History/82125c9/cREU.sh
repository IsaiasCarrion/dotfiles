#!/bin/bash
set -e

# --- VARIABLES ---
REPO_URL="https://github.com/IsaiasCarrion/dotfiles"
# El directorio donde se clona el repo
DOTFILES_DIR="$HOME/.dotfiles"
# El directorio fuente dentro del repo (si hay una carpeta anidada)
# Revisa la estructura de tu repo para asegurarte de que esta ruta es correcta
SOURCE_DOTFILES_DIR="$DOTFILES_DIR/dotfiles"

# --- MODO NO INTERACTIVO ---
NON_INTERACTIVE=false
if [[ "$1" == "-y" || "$1" == "--yes" ]]; then
    NON_INTERACTIVE=true
fi

ask_user() {
    if [ "$NON_INTERACTIVE" = true ]; then
        return 0
    fi
    read -r -p "$1 (s/n): " response
    [[ "$response" =~ ^([sS][iI]|[sS])$ ]]
}

# --- FUNCIONES (sin cambios en la lógica interna) ---
install_proprietary_packages() {
    if ask_user "¿Quieres instalar Google Chrome y Visual Studio Code?"; then
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
        echo "✅ Instalación de Visual Studio Code y Google Chrome completada."
    else
        echo "⏩ Omitiendo la instalación de programas propietarios."
    fi
}

install_system_packages() {
    local packages_to_install=(
        wget curl gnupg
        kitty rofi alacritty nvim zsh fzf bat eza nala
        python3 python3-pip pipx jq
        golang rustc cargo
        git gh
        jupyter-notebook
    )
    if ask_user "¿Quieres instalar los programas y lenguajes de desarrollo?"; then
        echo "Instalando paquetes del sistema..."
        sudo apt update
        sudo apt install -y "${packages_to_install[@]}"
        if command -v pipx &> /dev/null; then
            python3 -m pipx ensurepath
        fi
        echo "✅ Instalación de paquetes del sistema completada."
    else
        echo "⏩ Omitiendo la instalación de paquetes del sistema."
    fi
}

install_zinit() {
    if ask_user "¿Quieres instalar Zinit?"; then
        if [[ ! -d "$HOME/.zinit/bin" ]]; then
            echo "Clonando Zinit..."
            git clone https://github.com/zdharma-continuum/zinit.git "$HOME/.zinit/bin"
        else
            echo "Zinit ya está instalado. Actualizando..."
            git -C "$HOME/.zinit/bin" pull
        fi
         echo "✅ Zinit listo."
    else
        echo "⏩ Omitiendo la instalación de Zinit."
    fi
}

install_starship() {
    if ask_user "¿Quieres instalar Starship?"; then
        echo "Instalando Starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
        echo "✅ Starship instalado."
    else
        echo "⏩ Omitiendo la instalación de Starship."
    fi
}

install_docker() {
    if ask_user "¿Quieres instalar Docker y Docker Compose?"; then
        echo "Instalando Docker y Docker Compose..."
        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg; done
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
        echo "✅ Docker instalado. Por favor, reinicia tu sesión para que los permisos de grupo se apliquen."
    else
        echo "⏩ Omitiendo la instalación de Docker."
    fi
}

create_symlinks() {
    if ask_user "¿Quieres crear los enlaces simbólicos y copias para los dotfiles?"; then
        echo "Creando enlaces simbólicos y copias..."
        if [ ! -d "$SOURCE_DOTFILES_DIR" ]; then
            echo "❌ Error: El directorio de origen '$SOURCE_DOTFILES_DIR' no existe. Revisa la estructura del repositorio."
            exit 1
        fi
        if [ -d "$HOME/.config" ] && [ ! -L "$HOME/.config" ]; then
            echo "Moviendo el directorio ~/.config existente a ~/.config.bak"
            mv "$HOME/.config" "$HOME/.config.bak"
        fi
        mkdir -p "$HOME/.config"

        echo "Copiando .zshrc y .gitconfig desde el repositorio..."
        rm -f "$HOME/.zshrc"
        cp "$SOURCE_DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

        # rm -f "$HOME/.gitconfig"
        # cp "$SOURCE_DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

        echo "Creando enlaces simbólicos para las configuraciones..."
        ln -sf "$SOURCE_DOTFILES_DIR/.config/kitty" "$HOME/.config/kitty"
        ln -sf "$SOURCE_DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"
        ln -sf "$SOURCE_DOTFILES_DIR/.config/rofi" "$HOME/.config/rofi"
        ln -sf "$SOURCE_DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
        echo "✅ Enlaces simbólicos y copias creadas."
    else
        echo "⏩ Omitiendo la creación de enlaces simbólicos y copias."
    fi
}

configure_zsh() {
    if ask_user "¿Quieres configurar zsh como tu shell por defecto?"; then
        if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(which zsh)" ]]; then
            chsh -s "$(which zsh)"
            echo "✅ Zsh se ha establecido como tu shell por defecto. Reinicia tu sesión para aplicar los cambios."
        else
            echo "👌 Zsh ya es tu shell por defecto."
        fi
    else
        echo "⏩ Omitiendo la configuración de zsh."
    fi
}

# --- LÓGICA PRINCIPAL ---
echo "⚙️  Iniciando la configuración de dotfiles..."
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Clonando repositorio de dotfiles..."
    git clone --depth=1 "$REPO_URL" "$DOTFILES_DIR"
else
    echo "El directorio de dotfiles ya existe. Actualizando..."
    git -C "$DOTFILES_DIR" pull
fi

cd "$DOTFILES_DIR"
install_system_packages
install_zinit
install_starship
install_docker
create_symlinks
configure_zsh

echo ""
echo "🎉 Configuración de dotfiles completada. ¡Disfruta!"
