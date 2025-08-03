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

        # Lógica para crear enlaces simbólicos...
        # ... (el código de tu función create_symlinks) ...

        echo "✅ Enlaces simbólicos y copias creadas."
    else
        echo "⏩ Omitiendo la creación de enlaces simbólicos y copias."
    fi
}

link_configs
