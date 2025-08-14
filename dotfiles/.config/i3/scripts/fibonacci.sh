#!/bin/bash

# Este script abre una nueva ventana y la organiza en un layout de "maestro y pila"
# que simula un patron de fibonacci.
# La primera ventana ocupa la mitad del espacio, la segunda la mitad del restante, etc.

# Elige la aplicacion a lanzar (en este caso, alacritty)
APP="alacritty"

# Lanza la aplicacion
i3-msg "exec $APP"

# Espera un momento para que i3 reconozca la nueva ventana
sleep 0.1

# Obtiene la cantidad de ventanas en el espacio de trabajo actual
NUM_WINDOWS=$(i3-msg -t get_tree | jq '.. | select(.focused? and .focused==true) | .parent | .nodes | length')

if [ "$NUM_WINDOWS" -eq 1 ]; then
    # La primera ventana es el maestro
    i3-msg "resize set 50 ppt height"
    i3-msg "resize set 50 ppt width"
elif [ "$NUM_WINDOWS" -gt 1 ]; then
    # Las siguientes ventanas se dividen y se apilan
    i3-msg "split v"
    i3-msg "resize set 50 ppt height"
    i3-msg "split h"
fi
