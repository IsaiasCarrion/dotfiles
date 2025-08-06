#!/bin/sh
# Este script muestra el número de notificaciones de Dunst.

# Obtiene el número de notificaciones activas
COUNT=$(dunstctl count displayed | awk '{print $1}')

# Muestra el número de notificaciones
echo "$COUNT"
