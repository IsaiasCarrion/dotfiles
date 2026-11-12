# shellcheck shell=bash
# ~/.bash_profile — paquete "bash" (CachyOS/Arch).
# Shell de login: carga la configuración interactiva una sola vez.

if [[ -r "$HOME/.bashrc" ]]; then
    . "$HOME/.bashrc"
fi
