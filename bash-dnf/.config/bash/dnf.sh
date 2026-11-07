# ~/.config/bash/dnf.sh — paquete "bash-dnf" (Fedora).
# Lo carga ~/.bashrc si el archivo existe. No se ejecuta por sí solo.

command -v dnf >/dev/null 2>&1 || return 0

# Actualizar el sistema.
dnfup() {
    sudo dnf upgrade --refresh "$@"
}

# Buscar e instalar paquetes con fzf (multiselección).
pkgs() {
    command -v fzf >/dev/null 2>&1 || { echo "Instalá fzf: sudo dnf install fzf"; return 127; }

    local -a packages
    mapfile -t packages < <(
        dnf -q repoquery --available --qf '%{name}\t%{summary}' 2>/dev/null |
            fzf --multi --height=80% --layout=reverse --border \
                --delimiter='\t' --with-nth=1,2 \
                --prompt='📦 DNF > ' \
                --preview='dnf -q info {1} 2>/dev/null' \
                --preview-window=right:70% |
            cut -f1
    ) || return

    ((${#packages[@]} > 0)) || return 0
    sudo dnf install -- "${packages[@]}"
}

# Elegir paquetes instalados y eliminarlos tras confirmación.
pkgrm() {
    command -v fzf >/dev/null 2>&1 || { echo "Instalá fzf: sudo dnf install fzf"; return 127; }

    local pkgs answer
    local -a packages
    pkgs=$(
        rpm -qa --qf '%{NAME}\n' | sort -u |
            fzf --multi --height=80% --layout=reverse --border \
                --prompt='🗑️ Remove > ' \
                --preview='rpm -qi {} 2>/dev/null' \
                --preview-window=right:70%
    ) || return

    [[ -n "$pkgs" ]] || return 0
    echo
    printf 'Paquetes seleccionados:\n%s\n\n' "$pkgs"
    read -r -p "¿Eliminar los paquetes seleccionados? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]] || { echo "Operación cancelada."; return 0; }

    mapfile -t packages <<< "$pkgs"
    sudo dnf remove -- "${packages[@]}"
}

# Limpieza segura: quitar huérfanos y caché de paquetes.
pkgclean() {
    sudo dnf autoremove "$@"
    sudo dnf clean packages
}
