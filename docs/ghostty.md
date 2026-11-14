# Ghostty en Omarchy: tema intacto, preferencias separadas

## Regla

**Ghostty conserva exactamente el tema predeterminado de Omarchy.** Este
repositorio no enlaza, copia ni reemplaza `~/.config/ghostty/config`, y no
versiona colores, paletas ni un nombre de tema.

## Cómo funciona el tema

Omarchy entrega `~/.config/ghostty/config` con esta primera línea:

```ini
config-file = ?"~/.local/state/omarchy/current/theme/ghostty.conf"
```

El archivo `~/.local/state/omarchy/current/theme/ghostty.conf` lo regenera
Omarchy al cambiar de tema (`omarchy theme set ...`). Contiene `background`,
`foreground`, `cursor-color`, `selection-*` y `palette`. La configuración de
Ghostty también usa `window-theme = ghostty` y no fija `theme =`.

Por eso:

- No hay paquete Stow `ghostty/`.
- No se copia un tema de respaldo: la paleta estática antigua se eliminó.
- `scripts/deploy-dotfiles.sh` no toca `~/.config/ghostty/`.
- `scripts/verify.sh` falla si `~/.config/ghostty/config` es un enlace al repo,
  si define `theme =` o si deja de referenciar el tema dinámico de Omarchy.
- `scripts/test.sh` comprueba que el repo no tenga claves de tema/color.

## Preferencias personales (opcionales, sin tocar el tema)

Omarchy ya usa **JetBrainsMono Nerd Font**, `font-size = 9`, padding 14,
cursor en bloque sin parpadeo y `shell-integration-features = no-cursor,ssh-env`.
Si querés conservar preferencias propias, el repo incluye:

- `assets/ghostty/personal.conf`: solo opciones no visuales (tamaño de fuente,
  comportamiento de ventana, scrollback y atajos).
- `scripts/ghostty-personal.sh`: agrega o actualiza un bloque marcado al final de
  `~/.config/ghostty/config`, con respaldo previo, modo `--dry-run`, `--remove`
  e idempotencia. Rechaza claves de tema/color y valida con
  `ghostty +validate-config`; si Ghostty rechaza el resultado, restaura el
  respaldo.

El script **no lo ejecuta `bootstrap.sh`**. Es una decisión posterior y
explícita:

```bash
# Ver el diff sin cambios (seguro)
./scripts/ghostty-personal.sh --dry-run

# Aplicar (pide confirmación; Omarchy sigue siendo dueño del tema)
./scripts/ghostty-personal.sh

# Quitar solo el bloque personal
./scripts/ghostty-personal.sh --remove
```

El bloque queda entre:

```ini
# >>> dotfiles: preferencias personales (no tocar el tema de Omarchy) >>>
...
# <<< dotfiles: preferencias personales <<<
```

Si `omarchy refresh config ghostty/config` reemplaza el archivo, el bloque se
pierde y se puede volver a aplicar. El tema no se pierde porque lo genera
Omarchy.

## Verificación

```bash
ghostty +validate-config
ghostty +show-config --no-pager | grep -E '^(theme|config-file|font-size|background|foreground)'
grep -n 'changing the theme\|config-file' ~/.config/ghostty/config
./scripts/verify.sh --repo
```

Resultado esperado: `config-file` apunta al tema actual de Omarchy, no aparece
un `theme =` estático y `background`/`foreground` salen del archivo de tema.

## Actualizaciones de Omarchy

```bash
omarchy update
omarchy theme set <tema>
omarchy restart terminal
```

No hace falta reejecutar Stow ni el script personal después de un cambio de
tema. Si Omarchy reemplaza la configuración base, revisá si tu bloque personal
sigue presente; si no, `./scripts/ghostty-personal.sh` lo vuelve a aplicar sin
tocar los colores.
