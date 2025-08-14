#!/bin/bash
# scripts/configure-zsh.sh

# Se asegura de que las variables de ruta estén cargadas
source ./scripts/setup-paths.sh

# Función para manejar la interactividad. La duplicamos aquí para que el script sea autónomo.
ask_user() {
    if [ "$NON_INTERACTIVE" = true ]; then
        return 0 # Responde "sí" automáticamente
    fi
    read -r -p "$1 (s/n): " response
    [[ "$response" =~ ^([sS][iI]|[sS])$ ]]
}

# Lógica para configurar Zsh
configure_zsh() {
    if ask_user "¿Quieres configurar zsh como tu shell por defecto?"; then
        if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(which zsh)" ]]; then
            # Aquí está el código que faltaba
            sudo chsh -s "$(which zsh)" "$USER"
            echo "✅ Zsh se ha establecido como tu shell por defecto. Reinicia tu sesión para aplicar los cambios."
        else
            echo "👌 Zsh ya es tu shell por defecto."
        fi
    else
        echo "⏩ Omitiendo la configuración de zsh."
    fi
}

# Ejecuta la función
configure_zsh
