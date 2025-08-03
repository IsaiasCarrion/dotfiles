#!/bin/bash
# scripts/configure-zsh.sh

source ./scripts/setup-paths.sh

ask_user() {
    if [ "$NON_INTERACTIVE" = true ]; then return 0; fi
    read -r -p "$1 (s/n): " response
    [[ "$response" =~ ^([sS][iI]|[sS])$ ]]
}

configure_zsh() {
    if ask_user "¿Quieres configurar zsh como tu shell por defecto?"; then
        # ... (el código para configurar zsh) ...
    else
        echo "⏩ Omitiendo la configuración de zsh."
    fi
}

configure_zsh
