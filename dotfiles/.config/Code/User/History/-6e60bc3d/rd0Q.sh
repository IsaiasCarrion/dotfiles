#!/bin/bash
# scripts/configure-zsh.sh

# Se asegura de que las variables de ruta estén cargadas
source ./scripts/setup-paths.sh

# Función para manejar la interactividad
ask_user() {
    # ... (El código de la función ask_user) ...
    # Se ha omitido para mantener la concisión, pero debe estar en tu script principal
}

# Lógica para configurar Zsh
configure_zsh() {
    # El primer 'if' comprueba si el usuario quiere configurar zsh
    if ask_user "¿Quieres configurar zsh como tu shell por defecto?"; then
        # El segundo 'if' anidado comprueba si zsh ya es el shell por defecto
        if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(which zsh)" ]]; then
            chsh -s "$(which zsh)"
            echo "✅ Zsh se ha establecido como tu shell por defecto. Reinicia tu sesión para aplicar los cambios."
        else
            echo "👌 Zsh ya es tu shell por defecto."
        fi # Cierra el 'if' anidado

    # Si el usuario no quiere configurar zsh, se ejecuta este 'else'
    else
        echo "⏩ Omitiendo la configuración de zsh."
    fi # Cierra el 'if' principal
}

# Ejecuta la función
configure_zsh
