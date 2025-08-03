#!/bin/bash
# scripts/install-tools.sh

source ./scripts/setup-paths.sh

ask_user() {
    if [ "$NON_INTERACTIVE" = true ]; then return 0; fi
    read -r -p "$1 (s/n): " response
    [[ "$response" =~ ^([sS][iI]|[sS])$ ]]
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
install_warp_terminal() {
    if ask_user "¿Quieres instalar Warp Terminal?"; then
        echo "Instalando Warp Terminal..."
        curl -fsSL https://releases.warp.dev/linux/debian/warp.sh | sh
        echo "✅ Warp Terminal instalado."
    else
        echo "⏩ Omitiendo la instalación de Warp Terminal."
    fi
}

install_fonts() {
    if ask_user "¿Quieres instalar JetBrains Mono Nerd Font?"; then
        echo "Descargando e instalando JetBrains Mono Nerd Font..."
        local font_dir="$HOME/.local/share/fonts/JetBrainsMono"
        mkdir -p "$font_dir"
        curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip" -o /tmp/JetBrainsMono.zip
        unzip -o /tmp/JetBrainsMono.zip -d "$font_dir"
        rm /tmp/JetBrainsMono.zip
        fc-cache -f -v
        echo "✅ JetBrains Mono Nerd Font instalado."
    else
        echo "⏩ Omitiendo la instalación de la fuente."
    fi
}

install_zinit
install_starship
install_docker
install_warp_terminal
install_fonts
