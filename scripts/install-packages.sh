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
        # ... (el código de instalación de VS Code y Chrome) ...
        echo "✅ Instalación de Visual Studio Code y Google Chrome completada."
    else
        echo "⏩ Omitiendo la instalación de programas propietarios."
    fi
}

install_system_packages() {
    local packages_to_install=(
        # ... (la lista de paquetes a instalar) ...
    )
    if ask_user "¿Quieres instalar los programas y lenguajes de desarrollo?"; then
        echo "Instalando paquetes del sistema..."
        # ... (el código de instalación de paquetes del sistema) ...
        echo "✅ Instalación de paquetes del sistema completada."
    else
        echo "⏩ Omitiendo la instalación de paquetes del sistema."
    fi
}

install_system_packages
install_proprietary_packages
