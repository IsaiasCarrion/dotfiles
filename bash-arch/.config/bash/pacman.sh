# shellcheck shell=bash
# ~/.config/bash/pacman.sh — paquete "bash-arch" (CachyOS/Arch).
# Lo carga ~/.bashrc si el archivo existe. No se ejecuta por sí solo.

command -v pacman >/dev/null 2>&1 || return 0

# Actualizar el sistema.
pacup() {
    sudo pacman -Syu "$@"
}

# Buscar e instalar paquetes de los repositorios oficiales con fzf (multiselección).
pkgs() {
    command -v fzf >/dev/null 2>&1 || { echo "Instalá fzf: sudo pacman -S fzf"; return 127; }

    local -a packages
    mapfile -t packages < <(
        pacman -Slq |
            fzf --multi --height=80% --layout=reverse --border \
                --prompt='📦 pacman > ' \
                --preview='pacman -Si {} 2>/dev/null' \
                --preview-window=right:70%
    ) || return

    ((${#packages[@]} > 0)) || return 0
    sudo pacman -S --needed -- "${packages[@]}"
}

# Elegir paquetes instalados y eliminarlos tras confirmación.
pkgrm() {
    command -v fzf >/dev/null 2>&1 || { echo "Instalá fzf: sudo pacman -S fzf"; return 127; }

    local pkgs answer
    local -a packages
    pkgs=$(
        pacman -Qq | sort -u |
            fzf --multi --height=80% --layout=reverse --border \
                --prompt='🗑️ Remove > ' \
                --preview='pacman -Qi {} 2>/dev/null' \
                --preview-window=right:70%
    ) || return

    [[ -n "$pkgs" ]] || return 0
    echo
    printf 'Paquetes seleccionados:\n%s\n\n' "$pkgs"
    read -r -p "¿Eliminar los paquetes seleccionados? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] || { echo "Operación cancelada."; return 0; }

    mapfile -t packages <<< "$pkgs"
    sudo pacman -Rns -- "${packages[@]}"
}

# Limpieza segura: solo borra del caché paquetes que ya no están instalados.
pkgclean() {
    sudo pacman -Sc
}
