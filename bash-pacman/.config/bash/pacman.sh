# ~/.config/bash/pacman.sh — paquete "bash-pacman" (solo Arch/CachyOS).
# Lo carga ~/.bashrc si el archivo existe. No se ejecuta por sí solo.

command -v pacman >/dev/null 2>&1 || return 0

# Navegador de paquetes de los repositorios CachyOS (multiselección) e instalación.
pacs() {
    command -v fzf >/dev/null 2>&1 || { echo "Instalá fzf."; return 127; }
    command -v pacman-conf >/dev/null 2>&1 || { echo "No se encontró pacman-conf."; return 127; }

    local -a repos packages
    local pkg
    mapfile -t repos < <(pacman-conf --repo-list | grep '^cachyos')

    ((${#repos[@]} > 0)) || { echo "No se encontraron repositorios CachyOS."; return 1; }

    pkg=$(
        pacman -Slq "${repos[@]}" | sort -u |
            fzf --multi --height=80% --layout=reverse --border \
                --prompt='📦 CachyOS > ' \
                --preview='pacman -Si {} 2>/dev/null; echo; echo "────────────"; pacman -Fl {} 2>/dev/null | head -200' \
                --preview-window=right:70%
    ) || return

    [[ -n "$pkg" ]] || return 0
    mapfile -t packages <<< "$pkg"
    sudo pacman -S -- "${packages[@]}"
}

# Elegir paquetes instalados y eliminarlos tras confirmación.
pacrm() {
    command -v fzf >/dev/null 2>&1 || { echo "Instalá fzf."; return 127; }

    local pkgs answer
    local -a packages
    pkgs=$(
        pacman -Qq |
            fzf --multi --height=80% --layout=reverse --border \
                --prompt='🗑️ Remove > ' \
                --preview='pacman -Qi {} 2>/dev/null; echo; echo "────────────"; pactree -r {} 2>/dev/null | head -50' \
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
