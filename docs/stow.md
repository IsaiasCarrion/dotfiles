# GNU Stow: despliegue por paquete

Cada carpeta de primer nivel es un paquete Stow que reproduce su ruta bajo
`$HOME`. `.stowrc` contiene `--no-folding`, así que Stow enlaza **archivos
individuales** y no directorios completos (si enlazara `~/.config/git` entero,
todo lo que escriba Git terminaría dentro del repo).

## Paquetes

| Paquete | Destino | Cuándo desplegarlo |
|---|---|---|
| `bash` | `~/.bashrc`, `~/.bash_profile` | Siempre |
| `bash-arch` | `~/.config/bash/pacman.sh` | Siempre en Arch/Omarchy |
| `git` | `~/.gitconfig`, `~/.gitignore_global` | Siempre |
| `git-delta` | `~/.config/git/delta.gitconfig` | Solo si `command -v delta` |
| `opencode` | `~/.config/opencode/opencode.jsonc`, `AGENTS.md`, `dcp.jsonc`, plantilla | Siempre que uses OpenCode |

No hay paquetes `ghostty`, `starship` ni del escritorio. Esos archivos son de
Omarchy.

## Simular antes de aplicar (fase actual: solo simular)

```bash
cd ~/dotfiles

# Simulación sin escribir nada
stow -n -v bash bash-arch git opencode

# Incluir delta solo si está instalado
command -v delta && stow -n -v git-delta
```

`stow -n` muestra `LINK:` para lo que crearía y falla si hay un archivo real en
el destino. No crea enlaces ni mueve archivos.

## Despliegue real (fase posterior, no ejecutado en esta auditoría)

El script recomendado respalda conflictos antes de enlazar:

```bash
./scripts/deploy-dotfiles.sh --dry-run   # conflictos + simulación
./scripts/deploy-dotfiles.sh             # aplicar con confirmación
```

o manualmente, después de resolver conflictos:

```bash
cd ~/dotfiles
stow -v bash bash-arch git opencode
command -v delta && stow -v git-delta
```

Reglas:

- **Nunca** `stow --adopt`: adoptar sobrescribe el repo con lo que haya en
  `$HOME`.
- Si un archivo real existe en el destino, `deploy-dotfiles.sh` lo mueve a
  `~/.dotfiles-backup/<timestamp>/` con un `manifest.txt`.
- Si un enlace apunta a otro sitio, también se respalda; no se pisa.
- `--dry-run` no crea respaldos ni enlaces.

## Rehacer enlaces tras agregar/renombrar archivos

```bash
stow -R -v bash
```

## Retirar un paquete

```bash
stow -D -v git-delta
```

Borra solo los enlaces; los archivos del repo quedan intactos.

## Verificar

```bash
./scripts/verify.sh          # despliegue real + entorno Omarchy
./scripts/verify.sh --repo   # solo el repositorio, sin links en HOME
./scripts/test.sh            # pruebas completas en HOMEs temporales
```

## Vuelta atrás

```bash
cd ~/dotfiles
stow -D -v bash bash-arch git opencode
command -v delta && stow -D -v git-delta

backup="$(readlink -f ~/.dotfiles-backup/LATEST)"
cat "$backup/manifest.txt"
while IFS= read -r line; do
    orig="${line%% -> *}"
    dest="${line#* -> }"
    mkdir -p -- "$(dirname -- "$orig")"
    cp -a -- "$dest" "$orig"
done < "$backup/manifest.txt"
```

El manifiesto tiene el formato `origen -> respaldo`. El procedimiento solo
restaura lo que el script respaldó; no borra archivos ajenos al manifiesto.
