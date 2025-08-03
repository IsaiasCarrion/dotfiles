#!/bin/bash
set -e

# --- VARIABLES ---
REPO_URL="https://github.com/IsaiasCarrion/dotfiles"
DOTFILES_DIR="$HOME/.dotfiles"

# --- MODO NO INTERACTIVO ---
NON_INTERACTIVE=false
if [[ "$1" == "-y" || "$1" == "--yes" ]]; then
    NON_INTERACTIVE=true
fi

# --- FUNCIONES AUXILIARES ---
ask_user() {
    if [ "$NON_INTERACTIVE" = true ]; then
        return 0
    fi
    read -r -p "$1 (s/n): " response
    [[ "$response" =~ ^([sS][iI]|[sS])$ ]]
}

# --- LÓGICA PRINCIPAL ---
echo "⚙️  Iniciando la configuración de dotfiles..."

# Clona el repositorio si no existe
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Clonando repositorio de dotfiles..."
    git clone --depth=1 "$REPO_URL" "$DOTFILES_DIR" || { echo "❌ Error al clonar el repositorio."; exit 1; }
fi

cd "$DOTFILES_DIR"

# Da permisos de ejecución a todos los scripts
chmod +x ./scripts/*.sh

echo "Ejecutando scripts de instalación..."

# Sourcing de los scripts modulares
./scripts/setup-paths.sh
./scripts/install-packages.sh
./scripts/install-tools.sh
./scripts/link-configs.sh
./scripts/configure-zsh.sh

echo ""
echo "🎉 Configuración de dotfiles completada. ¡Disfruta!"
