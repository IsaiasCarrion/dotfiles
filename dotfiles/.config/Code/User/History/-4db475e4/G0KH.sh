#!/bin/bash
# scripts/install-packages.sh

source ./scripts/setup-paths.sh

ask_user() {
    if [ "$NON_INTERACTIVE" = true ]; then return 0; fi
    read -r -p "$1 (s/n): " response
    [[ "$response" =~ ^([sS][iI]|[sS])$ ]]
}

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
        kitty zsh fzf bat eza nala
        python3 python3-pip pipx jq
        golang rustc cargo
        git gh
        jupyter-notebook
        alacritty
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

install_system_packages
install_proprietary_packages
