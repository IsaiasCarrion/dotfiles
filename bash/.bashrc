# shellcheck shell=bash
# ~/.bashrc — paquete "bash" para Omarchy (Bash).
#
# Omarchy ya aporta y este archivo NO duplica:
#   - entorno (OMARCHY_PATH, mise, ~/.local/bin, shims de mise)
#   - aliases y funciones (/usr/share/omarchy/default/bash/rc)
#   - inicialización de mise, Starship, zoxide, fzf y bash-completion
#   - EDITOR, BROWSER, MANPAGER y BAT_THEME
#
# Acá solo viven preferencias personales, funciones propias y la carga del
# paquete "bash-arch" (pacman). Lo privado de cada equipo va en ~/.bashrc.local.

# ==============================================================================
# 1. Entorno de Omarchy (también en shells no interactivas)
# ==============================================================================

if [[ -r /usr/share/omarchy/default/bash/env-bootstrap ]]; then
    source /usr/share/omarchy/default/bash/env-bootstrap
fi
export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"

# ==============================================================================
# 2. Shells no interactivas: no cargar aliases, prompt ni bindings
# ==============================================================================

[[ $- == *i* ]] || return

# ==============================================================================
# 3. Defaults de Omarchy (aliases, funciones, mise, Starship, zoxide, fzf)
# ==============================================================================

if [[ -r "$OMARCHY_PATH/default/bash/rc" ]]; then
    source "$OMARCHY_PATH/default/bash/rc"
fi

# ==============================================================================
# PATH personal (Omarchy ya agrega ~/.local/bin y los shims de mise)
# ==============================================================================

__path_prepend() {
    [[ -d "$1" ]] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}
__path_prepend "$HOME/.cargo/bin"
__path_prepend "$HOME/go/bin"
unset -f __path_prepend
export PATH

# Fragmentos locales del sistema (~/.bashrc.d/*.sh; convención opcional).
if [[ -d "$HOME/.bashrc.d" ]]; then
    for _bashrc_fragment in "$HOME"/.bashrc.d/*; do
        [[ -r "$_bashrc_fragment" ]] && source "$_bashrc_fragment"
    done
    unset _bashrc_fragment
fi

# ==============================================================================
# HISTORIAL (preferencias personales; Omarchy define la base)
# ==============================================================================

HISTSIZE=100000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T  '

shopt -s histappend checkwinsize autocd cdspell dirspell globstar

# Guardar el historial en cada prompt (evita perderlo si la terminal se cierra mal).
if [[ ";${PROMPT_COMMAND:-};" != *";history -a;"* ]]; then
    PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi

# Desactivar el control de flujo (Ctrl+S / Ctrl+Q).
if [[ -t 0 ]]; then
    stty -ixon 2>/dev/null
fi

# ==============================================================================
# FZF: solo opciones personales; Omarchy ya carga los keybindings
# ==============================================================================

if command -v fzf >/dev/null 2>&1; then
    # fd se llama fdfind en Debian/Ubuntu.
    if command -v fd >/dev/null 2>&1; then
        __fzf_fd=fd
    elif command -v fdfind >/dev/null 2>&1; then
        __fzf_fd=fdfind
    fi
    if [[ -n "${__fzf_fd:-}" ]]; then
        export FZF_DEFAULT_COMMAND="$__fzf_fd --type f --hidden --exclude .git"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
    unset __fzf_fd

    if command -v bat >/dev/null 2>&1; then
        export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
    fi

    export FZF_DEFAULT_OPTS='
    --height=40%
    --layout=reverse
    --border
    --ansi
    --cycle
    --info=inline
    --prompt=❯
    --pointer=▶
    --marker=✓
    --preview-window=right:60%
    --bind=ctrl-u:preview-half-page-up
    --bind=ctrl-d:preview-half-page-down
    --bind=ctrl-f:preview-page-down
    --bind=ctrl-b:preview-page-up
    '
fi

# ==============================================================================
# PYTHON / UV
# ==============================================================================

# Activar ~/venvs/<nombre>, o ./venv / ./.venv si no se pasa nombre.
v() {
    local venv
    if [[ -n "${1:-}" ]]; then
        venv="${HOME}/venvs/$1"
        if [[ -f "$venv/bin/activate" ]]; then
            source "$venv/bin/activate"
            return 0
        fi
        printf 'Entorno no encontrado: %s\n' "$venv" >&2
        return 1
    fi

    for venv in venv .venv; do
        if [[ -f "$venv/bin/activate" ]]; then
            source "$venv/bin/activate"
            return 0
        fi
    done

    echo "No se encontró venv ni .venv." >&2
    return 1
}

mkvenv() {
    if [[ -z "${1:-}" ]]; then
        echo "Uso: mkvenv <nombre>"
        return 1
    fi
    if [[ "$1" == */* || "$1" == "." || "$1" == ".." ]]; then
        echo "Usá un nombre simple, sin rutas."
        return 1
    fi

    local target="${HOME}/venvs/$1"
    [[ -e "$target" ]] && { echo "Ya existe: $target"; return 1; }

    command -v uv >/dev/null 2>&1 || { echo "uv no está instalado."; return 127; }
    uv venv "$target"
}

_uv_run() {
    local action="$1"
    shift
    (($# > 0)) || { printf 'Uso: uv%s <paquete>\n' "${action:0:1}"; return 1; }
    command -v uv >/dev/null 2>&1 || { echo "uv no está instalado."; return 127; }
    [[ -n "${VIRTUAL_ENV:-}" ]] || {
        echo "Activá un entorno virtual primero con v."
        return 1
    }
    uv pip "$action" "$@"
}

uvi() { _uv_run install "$@"; }
uvu() { _uv_run uninstall "$@"; }
uvf() { uv pip freeze; }

uvs() {
    local req="${1:-requirements.txt}"
    [[ -f "$req" ]] || { echo "No se encontró: $req"; return 1; }
    [[ -n "${VIRTUAL_ENV:-}" ]] || {
        echo "Activá un entorno virtual primero con v."
        return 1
    }
    uv pip sync "$req"
}

# Herramientas globales de uv. (`uvx` queda libre: es el comando oficial de uv.)
uvti() { uv tool install "$@"; }
uvr()  { uv tool run "$@"; }
uvl()  { uv tool list; }
uvux() { uv tool uninstall "$@"; }

# ==============================================================================
# DIRECTORIOS Y ARCHIVOS
# ==============================================================================

# Crea directorios y archivos. Un nombre con punto es un archivo
# (foo.txt); para forzar un directorio terminalo en barra (.config/).
mkpaths() {
    (($# > 0)) || { echo "Uso: mkpaths dir/ ruta/archivo.ext ..."; return 1; }
    local item base
    for item in "$@"; do
        base="${item##*/}"
        if [[ "$item" == */ || "$base" != *.* ]]; then
            mkdir -p -- "$item" || return
        else
            if [[ "$item" == */* ]]; then
                mkdir -p -- "$(dirname -- "$item")" || return
            fi
            [[ -d "$item" ]] && { echo "Es un directorio: $item" >&2; return 1; }
            [[ -e "$item" ]] || touch -- "$item" || return
        fi
    done
}

# Extraer archivos comprimidos.
extract() {
    [[ $# -eq 1 && -f "$1" ]] || { echo "Uso: extract archivo.tar.gz"; return 1; }
    local f="$1"
    [[ "$f" == -* ]] && f="./$f"
    case "$f" in
        *.tar.bz2|*.tbz2) tar -xjf "$f" ;;
        *.tar.gz|*.tgz)   tar -xzf "$f" ;;
        *.tar.xz|*.txz)   tar -xJf "$f" ;;
        *.tar.zst)        tar --zstd -xf "$f" ;;
        *.tar)            tar -xf "$f" ;;
        *.bz2)            bunzip2 "$f" ;;
        *.gz)             gunzip "$f" ;;
        *.zip)            unzip "$f" ;;
        *.7z)             7z x "$f" ;;
        *.rar)            unrar x "$f" ;;
        *) printf 'Formato no soportado: %s\n' "$1"; return 1 ;;
    esac
}

# ==============================================================================
# GIT
# ==============================================================================

alias gs='git status'

# Commit + push con confirmación en cada paso. Muestra qué se va a agregar
# ANTES de hacer `git add --all`, para no subir un archivo por accidente.
gpush() {
    [[ $# -gt 0 ]] || { echo 'Uso: gpush "mensaje del commit"'; return 1; }
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        echo "No estás dentro de un repositorio Git."
        return 1
    }

    local branch remote answer
    branch=$(git branch --show-current) || return 1
    [[ -n "$branch" ]] || { echo "No se pudo determinar la rama actual."; return 1; }

    remote=$(git config --get "branch.${branch}.remote")
    remote="${remote:-origin}"
    git remote get-url "$remote" >/dev/null 2>&1 || {
        echo "No existe el remoto: $remote"
        return 1
    }

    echo "Estado actual:"
    git --no-pager status -sb
    read -r -p "¿Agregar TODO (git add --all) y commitear? [y/N]: " answer
    case "$answer" in
        [yY]|[yY][eE][sS]|[sS]|[sS][iI]) ;;
        *) echo "Cancelado. No se modificó nada."; return 0 ;;
    esac

    git add --all || return 1
    git commit -m "$1" || {
        echo "Commit cancelado o sin cambios."
        return 1
    }

    echo
    echo "Último commit:"
    git --no-pager log -1 --oneline --stat
    printf '\nRama: %s\nRemote: %s\nPush a: %s/%s\n\n' "$branch" "$remote" "$remote" "$branch"

    read -r -p "¿Continuar con el push? [y/N]: " answer
    case "$answer" in
        [yY]|[yY][eE][sS]|[sS]|[sS][iI]) git push "$remote" "$branch" ;;
        *) echo "Push cancelado. El commit local se conserva." ;;
    esac
}

# ==============================================================================
# ALIASES PERSONALES
# ==============================================================================

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias reload='source ~/.bashrc'
alias myip='curl -fsS https://ipecho.net/plain; echo'

# `zed` solo como atajo si el binario real se llama zeditor.
if command -v zeditor >/dev/null 2>&1 && ! command -v zed >/dev/null 2>&1; then
    alias zed='zeditor'
fi

# ==============================================================================
# READLINE
# ==============================================================================

bind 'set completion-ignore-case on'
bind 'set completion-map-case on'

# Flechas arriba/abajo: buscar en el historial lo que empieza como lo escrito.
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\eOA": history-search-backward'
bind '"\eOB": history-search-forward'

# ==============================================================================
# PACMAN (Arch/Omarchy: paquete "bash-arch")
# ==============================================================================

if [[ -r "$HOME/.config/bash/pacman.sh" ]]; then
    source "$HOME/.config/bash/pacman.sh"
fi

# ==============================================================================
# CONFIGURACIÓN LOCAL (no versionada): aliases con IPs, variables privadas, etc.
# ==============================================================================

if [[ -r "$HOME/.bashrc.local" ]]; then
    source "$HOME/.bashrc.local"
fi
