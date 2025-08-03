#!/bin/bash
# scripts/link-configs.sh

source ./scripts/setup-paths.sh

ask_user() {
    if [ "$NON_INTERACTIVE" = true ]; then return 0; fi
    read -r -p "$1 (s/n): " response
    [[ "$response" =~ ^([sS][iI]|[sS])$ ]]
}

link_configs() {
    if ask_user "¿Quieres crear los enlaces simbólicos y copias para los dotfiles?"; then
        echo "Creando enlaces simbólicos y copias..."

        if [ ! -d "$SOURCE_CONFIG_DIR" ]; then
            echo "❌ Error: El directorio de origen '$SOURCE_CONFIG_DIR' no existe. Revisa la estructura del repositorio."
            exit 1
        fi

        # Mueve .config existente a .config.bak si existe
        if [ -d "$HOME/.config" ] && [ ! -L "$HOME/.config" ]; then
            echo "Moviendo el directorio ~/.config existente a ~/.config.bak"
            mv "$HOME/.config" "$HOME/.config.bak"
        fi
        mkdir -p "$HOME/.config"

        # Copiamos .zshrc y .gitconfig desde el repositorio
        echo "Copiando .zshrc y .gitconfig desde el repositorio..."
        rm -f "$HOME/.zshrc"
        cp "$SOURCE_CONFIG_DIR/.zshrc" "$HOME/.zshrc"

        echo "Creando enlaces simbólicos para las configuraciones..."
        # Enlaces simbólicos para las carpetas dentro de .config
        ln -sf "$SOURCE_CONFIG_DIR/.config/kitty" "$HOME/.config/kitty"
        ln -sf "$SOURCE_CONFIG_DIR/.config/nvim" "$HOME/.config/nvim"
        ln -sf "$SOURCE_CONFIG_DIR/.config/rofi" "$HOME/.config/rofi"
        ln -sf "$SOURCE_CONFIG_DIR/.config/alacritty" "$HOME/.config/alacritty"

        # Enlace para Starship
        if [ ! -d "$HOME/.config/starship" ]; then
          mkdir -p "$HOME/.config/starship"
        fi
        ln -sf "$SOURCE_CONFIG_DIR/.config/starship/starship.toml" "$HOME/.config/starship/starship.toml"

        # Enlace para Warp-Terminal
        if [ ! -d "$HOME/.config/warp-terminal" ]; then
          mkdir -p "$HOME/.config/warp-terminal"
        fi
        ln -sf "$SOURCE_CONFIG_DIR/.config/warp-terminal/themes" "$HOME/.config/warp-terminal/themes"

        # Enlace para XFCE4
        if [ ! -d "$HOME/.config/xfce4" ]; then
            echo "Creando enlace simbólico para la configuración de XFCE4..."
            ln -sf "$SOURCE_CONFIG_DIR/.config/xfce4" "$HOME/.config/xfce4"
            echo "✅ Enlace simbólico de XFCE4 creado."
        else
            echo "👌 El directorio ~/.config/xfce4 ya existe. Omitiendo la creación del enlace simbólico."
        fi
        
        # --- NUEVA ADICIÓN PARA VS CODE ---
        if [ ! -d "$HOME/.config/Code" ]; then
            echo "Creando enlace simbólico para la configuración de VS Code..."
            mkdir -p "$HOME/.config/Code"
            ln -sf "$SOURCE_CONFIG_DIR/.config/Code/User" "$HOME/.config/Code/User"
            echo "✅ Enlace simbólico de VS Code creado."
        else
            echo "👌 El directorio ~/.config/Code ya existe. Omitiendo la creación del enlace simbólico."
        fi

        echo "✅ Enlaces simbólicos y copias creadas."
    else
        echo "⏩ Omitiendo la creación de enlaces simbólicos y copias."
    fi
}

link_configs
