#!/bin/bash
# scripts/install-tools.sh

source ./scripts/setup-paths.sh

ask_user() {
    if [ "$NON_INTERACTIVE" = true ]; then return 0; fi
    read -r -p "$1 (s/n): " response
    [[ "$response" =~ ^([sS][iI]|[sS])$ ]]
}

install_zinit() {
    # ... (el código para instalar Zinit) ...
}

install_starship() {
    # ... (el código para instalar Starship) ...
}

install_docker() {
    # ... (el código para instalar Docker) ...
}

install_zinit
install_starship
install_docker
