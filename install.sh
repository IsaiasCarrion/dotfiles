#!/usr/bin/env bash
# ===============================================
# Dotfiles Automated Installer (Refactorizado)
# Compatible: Ubuntu/Debian y Arch Linux
# Autor original: Isaias Carrion
# ===============================================

set -euo pipefail

# ----------- Helper Functions -----------
abort()   { echo -e "\n[ERROR] $1" >&2; exit 1; }
info()    { echo -e "\n[INFO] $1"; }
success() { echo -e "\n[SUCCESS] $1"; }
ask_user(){ [[ "${NON_INTERACTIVE:-false}" == true ]] && return 0; read -rp "$1 (s/n): " r; [[ "$r" =~ ^([sS][iI]|[sS])$ ]]; }

# ----------- 1. Verificaciones iniciales -----------
[[ $EUID -ne 0 ]] && abort "Ejecuta como root o con sudo."

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO="$ID"
else
    abort "No se pudo detectar la distribución."
fi

case "$DISTRO" in
    ubuntu|debian)
        PKG="apt"
        UPDATE_CMD="apt update"
        INSTALL_CMD="apt install -y"
        BUILD_ESSENTIAL="build-essential"
        ;;
    arch)
        PKG="pacman"
        UPDATE_CMD="pacman -Sy"
        INSTALL_CMD="pacman -S --noconfirm"
        BUILD_ESSENTIAL="base-devel"
        ;;
    *)
        abort "Distribución no soportada: $DISTRO"
        ;;
esac

info "Usando gestor de paquetes: $PKG"

# ----------- 2. Funciones de instalación genéricas -----------
install_packages() {
    local packages=("$@")
    info "Instalando paquetes: ${packages[*]}"
    $UPDATE_CMD
    $INSTALL_CMD "${packages[@]}" || abort "Fallo al instalar: ${packages[*]}"
}

install_from_url() {
    local url="$1" dest="$2" mode="${3:-755}"
    wget -O "$dest" "$url" || abort "No se pudo descargar: $url"
    chmod "$mode" "$dest"
}

# ----------- 3. Instalación de paquetes base -----------
install_packages curl wget git zsh python3 python3-pip neovim unzip tar "$BUILD_ESSENTIAL"

# ----------- 4. Programas adicionales -----------
install_docker() {
    if command -v docker &>/dev/null; then
        info "Docker ya está instalado."
        return
    fi

    info "Instalando Docker..."
    if [[ "$PKG" == "apt" ]]; then
        install_packages ca-certificates gnupg lsb-release
        install -d -m 0755 /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$ID/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/$ID $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
        $UPDATE_CMD
        install_packages docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        install_packages docker docker-compose
    fi
    usermod -aG docker "$SUDO_USER"
}

install_obsidian() {
    info "Instalando Obsidian..."
    if [[ "$PKG" == "apt" ]]; then
        local tmp=/tmp/obsidian.deb
        local url=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest |
                    grep browser_download_url | grep amd64.deb | cut -d '"' -f 4)
        install_from_url "$url" "$tmp"
        apt install -y "$tmp"
        rm -f "$tmp"
    else
        local url=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest |
                    grep browser_download_url | grep x86_64.AppImage | cut -d '"' -f 4)
        install_from_url "$url" /usr/local/bin/Obsidian.AppImage
    fi
}

install_vscode() {
    info "Instalando Visual Studio Code..."
    if [[ "$PKG" == "apt" ]]; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/keyrings/packages.microsoft.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] \
        https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
        $UPDATE_CMD
        install_packages code
    else
        install_packages code || install_packages code-bin
    fi
}

install_chrome() {
    info "Instalando Google Chrome..."
    if [[ "$PKG" == "apt" ]]; then
        local tmp=/tmp/chrome.deb
        install_from_url "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" "$tmp"
        apt install -y "$tmp"
        rm -f "$tmp"
    else
        info "Instalación directa de Chrome no soportada en Arch. Use Chromium o Flatpak."
    fi
}

# ----------- 5. Copia de configuraciones -----------
copy_dotfiles() {
    local DOTFILES_DIR="$(dirname "$0")/dotfiles"
    rsync -a --delete "$DOTFILES_DIR/.config/" "$HOME/.config/" || abort "No se pudo copiar .config"
    cp -f "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
}

set_i3blocks_permissions() {
    find "$HOME/.config/i3blocks" -type f -name "*.sh" -exec chmod +x {} +
}

# ----------- 6. Ejecución de scripts internos -----------
install_docker
install_obsidian
install_vscode
install_chrome
copy_dotfiles
set_i3blocks_permissions

# ----------- 7. Configuración de zsh -----------
if [[ "$(getent passwd "$SUDO_USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
    chsh -s "$(command -v zsh)" "$SUDO_USER"
fi

# ----------- 8. Finalización -----------
success "¡Instalación y configuración completadas!"
