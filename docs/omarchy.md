# Omarchy: qué administra el sistema y qué administra este repositorio

Este repositorio está pensado para **Omarchy 4.5** (Arch Linux + Hyprland +
Omarchy shell). Omarchy ya resuelve gran parte del escritorio y del entorno de
Bash; el repositorio solo agrega preferencias personales y herramientas que no
vienen en la imagen base.

## Detección

```bash
cat /etc/os-release          # ID=omarchy
omarchy version              # 4.5.0-3
echo "$XDG_CURRENT_DESKTOP"  # Hyprland
```

`scripts/lib.sh` acepta `ID=omarchy` y cualquier distribución con
`ID_LIKE=arch`. `scripts/verify.sh --repo` y `scripts/test.sh` no dependen de
tener el escritorio activo.

## Qué administra Omarchy (no lo toca este repo)

| Área | Rutas / mecanismo |
|---|---|
| Escritorio | `~/.config/hypr/*.lua`, Omarchy shell (`~/.config/omarchy/shell.json`) |
| Tema | `~/.local/state/omarchy/current/theme/`, `omarchy theme set` |
| Terminales | `~/.config/ghostty/config`, `~/.config/alacritty/`, `~/.config/foot/`, `~/.config/kitty/` |
| Bash | `/usr/share/omarchy/default/bash/*` (env, aliases, funciones, mise, Starship, zoxide, fzf) |
| Starship | `~/.config/starship.toml` y su inicialización en el rc de Omarchy |
| Git base | `~/.config/git/config` con aliases, identidad y credenciales de Omarchy |
| OpenCode base | `~/.config/opencode/opencode.json` (solo `update: disable`) y `cli.json` |
| Paquetes | `omarchy pkg`, imagen base, `yay` incluido |

No edites `/usr/share/omarchy/`: se reemplaza en cada actualización. Para
personalizar, usá `~/.config/` y las rutas de usuario que Omarchy documenta.

## Qué administra este repositorio

| Paquete Stow | Destino | Contenido |
|---|---|---|
| `bash` | `~/.bashrc`, `~/.bash_profile` | Carga el rc de Omarchy y agrega preferencias/funciones personales |
| `bash-arch` | `~/.config/bash/pacman.sh` | Funciones `pacup`, `pkgs`, `pkgrm`, `pkgclean` |
| `git` | `~/.gitconfig`, `~/.gitignore_global` | Complementos sobre el Git de Omarchy; identidad local |
| `git-delta` | `~/.config/git/delta.gitconfig` | Pager opcional; solo si `delta` existe |
| `opencode` | `~/.config/opencode/*.jsonc`, `AGENTS.md` | Configuración global V2 que se fusiona sobre la de Omarchy |

## Qué NO administra

- **Ghostty**: el tema y la configuración base son de Omarchy. Ver
  [ghostty.md](ghostty.md).
- **Starship**: Omarchy ya lo instala, configura e inicializa. No hay paquete
  `starship` en el repo.
- **Shell**: Omarchy usa Bash. No hay script para cambiar `/etc/shells` ni
  `chsh`.
- **Docker**: Omarchy lo instala por defecto; el repo no lo reinstala ni lo
  habilita. Podman queda como opción en `packages/optional.txt`.
- **Escritorio, Hyprland, Omarchy shell y temas**: nunca se stowean.

## Cómo se combinan Bash y Omarchy

`bash/.bashrc` hace, en este orden:

1. Carga `/usr/share/omarchy/default/bash/env-bootstrap` (`OMARCHY_PATH`, mise,
   PATH) incluso en shells no interactivas.
2. Corta si el shell no es interactivo.
3. Carga `/usr/share/omarchy/default/bash/rc`, que aporta aliases, funciones,
   mise, Starship, zoxide, fzf y completados.
4. Agrega solo lo personal: PATH de Cargo/Go, historial extendido, funciones de
   venv/uv, `extract`, `mkpaths`, `gpush`, alias de seguridad y el fragmento de
   pacman.

Por eso el repo **no** inicializa Starship, zoxide ni fzf, y **no** define
`EDITOR`, `BROWSER` ni `MANPAGER`.

## Cómo se combinan Git y Omarchy

Git lee primero `~/.config/git/config` (Omarchy) y después `~/.gitconfig`
(repo). El repo no repite identidad ni ajustes generales: solo agrega aliases,
`excludesfile`, `init.defaultBranch=main`, includes de delta/local y un helper
de credenciales portable (`gh` en PATH) que reemplaza la ruta versionada de mise
de Omarchy. Si preferís el helper de Omarchy, borrá ese bloque de
`git/.gitconfig`.

La identidad vive en `~/.config/git/config` (la configuró Omarchy) o en
`~/.gitconfig.local`, que se incluye al final y tiene prioridad.

## Actualizaciones

```bash
omarchy update          # o: sudo pacman -Syu
cd ~/dotfiles && git pull --ff-only
./bootstrap.sh          # idempotente: solo completa lo que falte
./scripts/verify.sh
```

Si una actualización de Omarchy reemplaza un archivo que el repo enlaza
(`~/.bashrc`, `~/.gitconfig`, `~/.config/opencode/*`), `deploy-dotfiles.sh`
detecta el conflicto y lo mueve a `~/.dotfiles-backup/<timestamp>/` antes de
volver a enlazar. No usa `stow --adopt`.
