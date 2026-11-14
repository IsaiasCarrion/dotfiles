# shellcheck shell=bash
# ~/.bash_profile — paquete "bash" para Omarchy.
#
# Bash lee /etc/profile antes que este archivo; Omarchy ya define ahí el
# entorno de sesión. Solo hay que cargar la configuración interactiva una vez.

if [[ -r "$HOME/.bashrc" ]]; then
    source "$HOME/.bashrc"
fi
