#!/bin/zsh

# ---| Carga Temprana de PATHs y Interactividad |--- #
# Solo cargar el script si es una sesión interactiva (no en scripts o entornos no interactivos)
[[ $- != *i* ]] && return

# Define PATH para comandos de pipx. Es mejor que esté al principio.
export PATH="$PATH:/home/izzy/.local/bin"

# ---| Zinit Autoinstalación y Carga |--- #
if [[ ! -f "${HOME}/.zinit/bin/zinit.zsh" ]]; then
  echo "Instalando Zinit..."
  mkdir -p "${HOME}/.zinit" && \
  git clone https://github.com/zdharma-continuum/zinit.git "${HOME}/.zinit/bin"
fi
source "${HOME}/.zinit/bin/zinit.zsh"

# ---| Plugins via Zinit |--- #
zinit light zsh-users/zsh-syntax-highlighting
zinit light junegunn/fzf

# ---| Plugings Setup |--- #
# CORREGIDO: Usar la ruta correcta para la instalación de fzf vía apt
[ -f "/usr/share/fzf/key-bindings.zsh" ] && source "/usr/share/fzf/key-bindings.zsh"
source /usr/share/doc/fzf/examples/key-bindings.zsh

# ---| Starship Prompt |--- #
if ! command -v starship &> /dev/null; then
  echo "Instalando Starship..."
  curl -sS https://starship.rs/install.sh | sh
fi
eval "$(starship init zsh)"

# ---| Paths de Caché |--- #
typeset -g comppath="$HOME/.cache"
typeset -g compfile="$comppath/.zcompdump"
[[ -d "$comppath" ]] || mkdir -p "$comppath"
[[ -w "$compfile" ]] || rm -f "$compfile" &>/dev/null

# ---| Shell Interno |--- #
SHELL=$(command -v zsh || echo '/bin/zsh')
KEYTIMEOUT=1
SAVEHIST=10000
HISTSIZE=10000
HISTFILE="$comppath/.zsh_history"

# ---| Inicialización de módulos |--- #
autoload -U compinit; compinit -u -d "$compfile"
autoload -U promptinit; promptinit
autoload -U terminfo
zmodload -i zsh/complist

# ---| Opciones del Shell |--- #
setopt CORRECT
setopt NO_NOMATCH
setopt LIST_PACKED
setopt ALWAYS_TO_END
setopt GLOB_COMPLETE
# setopt COMPLETE_ES
setopt COMPLETE_IN_WORD
setopt AUTO_CD
setopt AUTO_CONTINUE
setopt LONG_LIST_JOBS
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt EXTENDED_GLOB
setopt TRANSIENT_RPROMPT
setopt INTERACTIVE_COMMENTS

# ---| History Navigation Mejorada |--- #
autoload -U up-line-or-beginning-search; zle -N up-line-or-beginning-search
autoload -U down-line-or-beginning-search; zle -N down-line-or-beginning-search

# ---| Fix para teclas especiales |--- #
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    zle-line-init() { echoti smkx }
    zle -N zle-line-init
    zle-line-finish() { echoti rmkx }
    zle -N zle-line-finish
fi

# ---| Funciones útiles |--- #
toppy() {
    history | awk '{CMD[$2]++;count++;}END { for (a in CMD) print CMD[a], CMD[a]/count*100 "%", a;
    }' \
    | grep -v "./" | column -c3 -s " " -t | sort -nr | nl | head -n 21
}

file_amount() {
    ls -l | wc -l
}

cd() {
    builtin cd "$@" && command ls --group-directories-first --color=auto -F
}

src() {
    autoload -Uz compinit zrecompile
    rm -f "$compfile"(N)
    compinit -u -d "$compfile"
    zrecompile -p "$compfile" 2>/dev/null
    echo "Completado recargado."
}

reload-zsh() {
    exec zsh
}

npacs() {
  local query="${1:-}"

  for cmd in nala fzf apt-cache;
  do
    command -v "$cmd" >/dev/null || {
      echo "Error: '$cmd' no está instalado." >&2
      return 1
    }
  done

  local has_apt_file=""
  if command -v apt-file >/dev/null; then
    has_apt_file=1
  fi

  apt-cache dumpavail 2>/dev/null | awk '/^Package:/ {print $2}' | sort -u | \
    fzf --multi --query="$query" --prompt="Paquete > " --preview-window=up:70% --height=90% --border \
      --preview="bash -c '
        echo \"--- Información de: {} ---\";
        apt-cache show {} 2>/dev/null | head -n 20;
        if [ \"$has_apt_file\" ]; then
          echo \"\n--- Archivos de: {} ---\";
          apt-file list {} 2>/dev/null | head -n 20;
        fi
      '" | \
    xargs -r sudo nala install -y
}

npipx() {
  local query="${1:-}"

  for cmd in pipx fzf curl jq;
  do
    command -v "$cmd" >/dev/null || {
      echo "Error: '$cmd' no está instalado." >&2
      return 1
    }
  done

  local selection=$(curl -s "https://pypi.org/simple/" | \
    sed -E 's|<a href=.*>(.*)</a>|\1|' | sort -u | \
    fzf --multi --query="$query" --prompt="PyPI (pipx) > " --preview='
      curl -s https://pypi.org/pypi/{}/json | jq -r ".info | \"Name: \(.name)\nVersion: \(.version)\nSummary: \(.summary)\nHome Page: \(.home_page)\"" 2>/dev/null
    ')

  [ -n "$selection" ] && echo "$selection" | \
    xargs -r -n1 pipx install
}

npip() {
  local query="${1:-}"

  for cmd in pip fzf curl jq;
  do
    command -v "$cmd" >/dev/null || {
      echo "Error: '$cmd' no está instalado." >&2
      return 1
    }
  done

  local selection=$(curl -s "https://pypi.org/simple/" | \
    sed -E 's|<a href=.*>(.*)</a>|\1|' | sort -u | \
    fzf --multi --query="$query" --prompt="PyPI > " --preview='
      curl -s https://pypi.org/pypi/{}/json | jq -r ".info | \"Name: \(.name)\nVersion: \(.version)\nSummary: \(.summary)\nHome Page: \(.home_page)\"" 2>/dev/null
    ')

  [ -n "$selection" ] && echo "$selection" | \
    xargs -r -n1 pip install
}

# Activar entornos virtuales de Python
function v() {
    if [ -n "$1" ]; then
        VENV_PATH="$HOME/venvs/$1"
        if [ -f "$VENV_PATH/bin/activate" ]; then
            echo "Activando entorno: $VENV_PATH"
            source "$VENV_PATH/bin/activate"
            return
        else
            echo "No se encontró entorno en: $VENV_PATH"
        fi
    fi

    for local_env in "venv" ".venv"; do
        if [ -f "$local_env/bin/activate" ]; then
            echo "Activando entorno local: $local_env"
            source "$local_env/bin/activate"
            return
        fi
    done

    echo "Error: No se encontró un entorno virtual."
    echo "Buscado en: $HOME/venvs/$1, ./venv/, ./.venv/"
    return 1
}

# Crear entorno virtual en ~/venvs/
function mkvenv() {
    if [ -z "$1" ]; then
        echo "Uso: mkvenv <nombre>"
        return 1
    fi
    python3 -m venv "$HOME/venvs/$1" && echo "Entorno '$1' creado en $HOME/venvs"
}

# Automatiza el flujo de git add, commit y push
function gpush() {
  # Verifica si se proporcionó un mensaje de commit
  if [ -z "$1" ]; then
    echo "Error: Debes proporcionar un mensaje de commit."
    echo "Uso: gpush \"Tu mensaje de commit\""
    return 1
  fi

  # 1. git add --all
  echo "Añadiendo todos los archivos modificados con 'git add --all'..."
  git add --all

  # 2. git commit -m
  echo "Realizando commit con el mensaje: '$1'"
  git commit -m "$1"

  # Verifica si el commit fue exitoso
  if [ $? -ne 0 ]; then
    echo "El commit falló. No se realizará el push."
    return 1
  fi

  # 3. Pregunta antes de hacer el push
  echo ""
  echo "Resumen de los cambios a subir:"
  git --no-pager log -1 --stat

  # Pide confirmación al usuario (versión compatible con Zsh)
  print -n "¿Estás seguro de que quieres hacer 'git push'? (y/n): "
  read -r reply
  echo

  if [[ $reply =~ ^[Yy]$ ]]; then
    # 4. git push
    echo "Realizando 'git push'..."
    git push
  else
    echo "Operación cancelada. No se realizó el push."
  fi
}

# ---| Aliases útiles |--- #
alias ll='ls -lah --group-directories-first --color=auto'
alias ..='cd ..'
alias gs='git status'
alias grep='grep --color=auto'
alias install='sudo nala install'
alias nup='sudo nala update && nala upgrade'
alias ls='eza -lF --git --icons'
alias ll='eza -alF --git --icons'
alias bat='batcat'

# ---| Estilos de Autocompletado |--- #
zstyle ':completion:*:correct:*' original true
zstyle ':completion:*:correct:*' insert-unambiguous true
zstyle ':completion:*:approximate:*' max-errors 'reply=($(( ($#PREFIX + $#SUFFIX) / 3 )) numeric)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$comppath"
zstyle ':completion:*' rehash true
zstyle ':completion:*' verbose true
zstyle ':completion:*' insert-tab false
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:-command-:*:' verbose false
zstyle ':completion::complete:*' gain-privileges 1
zstyle ':completion:*:manuals.*' insert-sections true
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*' completer _complete _match _approximate _ignored
zstyle ':completion:*' matcher-list \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*' group-name ''
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' format ' %F{green}->%F{yellow} %d%f'
zstyle ':completion:*:messages' format ' %F{green}->%F{purple} %d%f'
zstyle ':completion:*:descriptions' format ' %F{green}->%F{yellow} %d%f'
zstyle ':completion:*:warnings' format ' %F{green}->%F{red} no matches%f'
