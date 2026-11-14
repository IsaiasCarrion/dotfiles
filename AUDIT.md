# Auditoría y migración a Omarchy 4.5

Fecha: 2026-11-14. Objetivo: dejar este repositorio autosuficiente en **Omarchy
4.5.0-3 (Arch Linux)** con Bash, GNU Stow, Ghostty, Zed, Obsidian, OpenCode y
Git, dejando que Omarchy administre el escritorio, el tema de la terminal,
Starship, los valores por defecto de Bash y la configuración base de Git.

> Esta fase fue **de solo lectura sobre el sistema real**. No se instaló ningún
> paquete, no se creó ningún enlace en `$HOME`, no se modificó ningún archivo de
> Omarchy y no se hizo ningún commit. Todas las pruebas de despliegue corrieron
> en un `HOME` temporal bajo `mktemp`.

## 1. Estado inicial encontrado

- Distribución: Omarchy 4.5.0-3, basada en Arch, sesión Hyprland/Wayland.
- Shell: Bash 5.3.20 (`/usr/bin/bash`), ya era la shell de login.
- Terminal: Ghostty 1.4.0+omarchy.1. Omarchy entrega su configuración y paleta:
  `~/.config/ghostty/config` carga
  `~/.local/state/omarchy/current/theme/ghostty.conf`; no existe una línea
  estática `theme =`.
- Omarchy ya provee y configura: Hyprland, la shell/barra de Omarchy, Themes,
  Starship, Bash (`/usr/share/omarchy/default/bash/`), la configuración base de
  Git (`~/.config/git/config`), la configuración base de OpenCode, Docker,
  `yay`, `mise`, `ghostty`, `obsidian`, `zoxide`, `fzf`, `bat`, `eza`, `fd`,
  `ripgrep`, `tmux`, `neovim`, `python` y más.
- `gh` (2.104.0), `opencode` (2.3.0) y `uv` (0.13.8) están instalados mediante la
  configuración mise de Omarchy (`/etc/mise/conf.d/omarchy-tools.toml`), no por
  pacman.
- El repositorio conservaba la forma de su etapa anterior (CachyOS/DMS/Fedora):
  un paquete Stow `ghostty/`, otro `starship/`, una paleta estática de Ghostty en
  `assets/ghostty/dankcolors`, `scripts/set-shell.sh`,
  `scripts/install-docker.sh` y documentación específica de CachyOS.
- Conflictos reales en `$HOME`: `~/.bashrc` y `~/.bash_profile` existen como
  archivos reales. `~/.gitconfig`, `~/.config/bash/pacman.sh` y
  `~/.config/opencode/opencode.jsonc` todavía no existen.
- No están instalados `stow`, `zed`, `7zip`, `tree` ni `git-delta`. `opencode` y
  `gh` sí están disponibles en `PATH` vía mise.

## 2. Problemas encontrados

| # | Problema | Riesgo | Corrección |
|---|---|---|---|
| 1 | El repo traía su propia config y paleta de Ghostty | Pisaría el tema dinámico de Omarchy | Se eliminaron `ghostty/` y la paleta; las preferencias personales son opcionales y nunca tocan tema/color |
| 2 | El repo traía una config de Starship | Duplica el valor por defecto de Omarchy | Se eliminó `starship/`; Starship queda en manos de Omarchy |
| 3 | `deploy-dotfiles.sh` stoweaba `ghostty` y `starship` | Competía por archivos de Omarchy | Despliega solo `bash`, `bash-arch`, `git`, `opencode` (+ `git-delta` opcional) |
| 4 | `.bashrc` reinicializaba Starship/zoxide/fzf y cargaba `/etc/bashrc` de Fedora | Inicialización duplicada y archivo global incorrecto | Carga `env-bootstrap` y `default/bash/rc` de Omarchy; conserva solo agregados personales |
| 5 | `.gitconfig` fijaba identidad y duplicaba ajustes de Omarchy | Divergencia y filtración de datos | Reducido a complementos portables; la identidad queda en Omarchy/config local |
| 6 | `github-cli` figuraba como dependencia pacman | Duplica el `gh` de mise | Se eliminó de los manifiestos |
| 7 | `opencode` y `uv` se trataban como paquetes pacman | Instalaría una segunda copia junto a mise | El instalador omite las herramientas declaradas por mise de Omarchy |
| 8 | Existía `scripts/set-shell.sh` | Innecesario: Omarchy ya usa Bash | Eliminado |
| 9 | Existía `scripts/install-docker.sh` | Omarchy ya provee Docker | Eliminado; Podman pasa a opcionales |
| 10 | Docs de CachyOS/DMS y un doc obsoleto de hardening | Instrucciones engañosas | Eliminados; reemplazados por guías de Omarchy, Stow, Ghostty, reinstalación y post-instalación |
| 11 | No había suite de pruebas offline | Las regresiones se descubrían recién al desplegar | Se agregó `scripts/test.sh` con HOMEs temporales |
| 12 | `verify.sh` asumía que todo venía de pacman | Falsos negativos con comandos de mise | Las comprobaciones de aplicaciones aceptan un comando funcional en `PATH` |
| 13 | Los ajustes personales de Ghostty no tenían un camino seguro | Riesgo de editar a mano la config de Omarchy | Se agregó `scripts/ghostty-personal.sh` con bloque marcado, respaldo, `--dry-run` y `--remove` |

## 3. Cambios realizados

### 3.0 Decisiones de arquitectura

- **Omarchy manda en el sistema**: escritorio, temas, Ghostty, Starship, Bash,
  configuración base de Git/OpenCode y Docker no se versionan ni se pisan.
- **El repositorio solo aporta capas personales** mediante paquetes Stow
  pequeños; no reemplaza archivos completos de Omarchy.
- **mise es la fuente de verdad** para `gh`, `opencode` y `uv` en Omarchy. El
  instalador y `verify.sh` los reconocen y evitan el paquete pacman duplicado.
- **Ghostty conserva el tema predeterminado**; las preferencias personales son
  opt-in, sin claves de tema/color, con respaldo y `--remove`.
- **Nunca se usa `stow --adopt`**: los conflictos se mueven a
  `~/.dotfiles-backup/<timestamp>/`, nunca se sobrescriben en silencio.
- **Bash es la shell objetivo**; no hay `chsh`, Fish ni Zsh.

### 3.1 Límites de propiedad de Omarchy

Documentado en `docs/omarchy.md`. Omarchy administra y este repositorio **no**
gestiona:

- Hyprland, la shell/barra de Omarchy, temas, atajos y monitores.
- `~/.config/ghostty/config` y el archivo de tema activo.
- `~/.config/starship.toml`.
- Los valores por defecto de Bash y el bootstrap de entorno en
  `/usr/share/omarchy/`.
- La configuración base de Git en `~/.config/git/config`.
- El `~/.config/opencode/opencode.json` base de OpenCode (actualizaciones
  desactivadas).
- Docker y el conjunto base de paquetes.

### 3.2 Shell

- `bash/.bashrc` ahora:
  - carga `/usr/share/omarchy/default/bash/env-bootstrap`;
  - carga `$OMARCHY_PATH/default/bash/rc` exactamente una vez;
  - carga `~/.config/bash/pacman.sh`;
  - conserva solo alias personales, ajustes independientes del prompt y agregados
    de `PATH`;
  - no vuelve a inicializar Starship, zoxide ni fzf.
- `bash/.bash_profile` carga `~/.bashrc` una sola vez.
- `bash-arch/.config/bash/pacman.sh` aporta ayudas específicas de Arch.

### 3.3 Git

- `git/.gitconfig` complementa la config de Omarchy en
  `~/.config/git/config`.
- No fija nombre, email ni clave de firma.
- Conserva el credential helper portable de `gh` y valores personales que no
  chocan con Omarchy.
- `git-delta` sigue siendo opcional: su paquete Stow se despliega solo cuando
  existe `delta`.

### 3.4 OpenCode

- `opencode/.config/opencode/opencode.jsonc` se superpone a
  `opencode.json` de Omarchy (OpenCode fusiona las configs globales; no las
  reemplaza).
- Se preservan `AGENTS.md`, `dcp.jsonc` y el ejemplo de OmniRoute.
- `opencode` se usa tal como lo provee Omarchy vía mise; no se instala el paquete
  pacman encima.

### 3.5 Ghostty

- Stow no despliega ninguna config ni paleta de Ghostty.
- `assets/ghostty/personal.conf` contiene solo preferencias personales neutras
  respecto al tema.
- `scripts/ghostty-personal.sh`:
  - rechaza claves de tema/color;
  - agrega un único bloque delimitado por marcadores a
    `~/.config/ghostty/config`;
  - respalda el archivo original;
  - admite `--dry-run` y `--remove`;
  - es idempotente y preserva la línea `config-file` del tema de Omarchy.

### 3.6 Paquetes

- Los manifiestos son solo Arch/Omarchy y no contienen entradas de
  Fedora/COPR/Flatpak.
- `install-packages.sh`:
  - instala solo lo ausente con `pacman -S --needed --noconfirm`;
  - nunca actualiza el sistema implícitamente;
  - omite los paquetes que Omarchy provee mediante mise;
  - verifica disponibilidad antes de instalar y falla con un mensaje claro si la
    base de datos de sync está vieja.
- `gh` se eliminó de los manifiestos porque Omarchy lo provee vía mise.

### 3.7 Herramientas y documentación

- Se agregó `scripts/test.sh` (53 comprobaciones offline, HOMEs temporales).
- `verify.sh` detecta si `gh`, `opencode` o `uv` están disponibles por mise y
  avisa si además se instaló el paquete pacman equivalente.
- Se agregaron docs: `docs/omarchy.md`, `docs/ghostty.md`, `docs/stow.md`,
  `docs/reinstall.md`, `docs/post-install.md`.
- Se reescribieron `README.md`, `AUDIT.md`, `docs/applications.md` y
  `docs/opencode.md`.

## 4. Archivos agregados, modificados y eliminados

### Agregados

- `assets/ghostty/personal.conf`
- `scripts/ghostty-personal.sh`
- `scripts/test.sh`
- `docs/omarchy.md`
- `docs/ghostty.md`
- `docs/stow.md`
- `docs/reinstall.md`
- `docs/post-install.md`

### Modificados

- `README.md`
- `AUDIT.md`
- `bootstrap.sh`
- `bash/.bashrc`
- `bash/.bash_profile`
- `git/.gitconfig`
- `packages/base.txt`
- `packages/common.txt`
- `packages/apps.txt`
- `packages/optional.txt`
- `scripts/bootstrap.sh`
- `scripts/lib.sh`
- `scripts/install-packages.sh`
- `scripts/deploy-dotfiles.sh`
- `scripts/verify.sh`
- `scripts/diagnose-system.sh`
- `scripts/install-addy-skills.sh`
- `docs/applications.md`
- `docs/opencode.md`

### Eliminados

- `ghostty/.config/ghostty/config`
- `starship/.config/starship.toml`
- `assets/ghostty/dankcolors`
- `scripts/set-shell.sh`
- `scripts/install-docker.sh`
- `docs/cachyos-post-install.md`
- `docs/cachyos-reinstall.md`
- `docs/dms.md`

## 5. Manifiesto definitivo de paquetes

```
base:     stow curl jq 7zip
common:   bash-completion ripgrep fzf fd bat eza zoxide starship tmux neovim
          tree python uv git-delta
apps:     ghostty zed opencode obsidian
optional: go rust podman obs-studio
```

Notas:

- Omarchy ya provee bash, git, curl, tar, gzip, unzip, findutils, util-linux,
  sudo y ca-certificates, así que no se repiten.
- `gh` lo provee Omarchy mediante mise y está ausente a propósito.
- `uv`, `opencode` y `gh` los omite el instalador en Omarchy porque mise los
  provee; siguen en los manifiestos para instalaciones de Arch puro.
- `docker` no figura: lo provee Omarchy. Podman es opcional.

## 6. Estructura final de Stow

```
dotfiles/
├── .stowrc
├── bash/                 → ~/.bashrc, ~/.bash_profile
├── bash-arch/            → ~/.config/bash/pacman.sh
├── git/                  → ~/.gitconfig, ~/.gitignore_global
├── git-delta/            → ~/.config/git/delta.gitconfig (solo si existe delta)
└── opencode/             → ~/.config/opencode/{opencode.jsonc,dcp.jsonc,
                             AGENTS.md,opencode.omniroute.example.jsonc}
```

`ghostty`, `starship` y el escritorio de Omarchy están deliberadamente ausentes.

## 7. Pruebas ejecutadas

Todas las pruebas de despliegue usaron HOMEs temporales. No se tocó el `$HOME`
real y nunca se creó `~/.dotfiles-backup`.

| Prueba | Resultado |
|---|---|
| `bash -n` sobre `bootstrap.sh`, todos los `scripts/*.sh`, `.bashrc`, `.bash_profile`, `pacman.sh` | Pasó |
| ShellCheck | Omitido: no está instalado (no se agregó como dependencia) |
| Parseo JSONC de los tres archivos de OpenCode | Pasó |
| Nombres de paquetes duplicados entre manifiestos | Ninguno |
| Disponibilidad de paquetes en los repos oficiales de Arch | Todos disponibles |
| Detección de mise de Omarchy (`gh`, `opencode`, `uv`) | Pasó |
| El instalador no duplica herramientas provistas por mise | Pasó |
| Ausencia de `stow --adopt` | Pasó |
| Ausencia de paquetes Ghostty/Starship en el repo | Pasó |
| El fragmento personal de Ghostty no tiene claves de tema/color | Pasó |
| Sin referencias obsoletas a Fedora/CachyOS/DMS en scripts/paquetes | Pasó |
| Config de Git válida y sin identidad fija | Pasó |
| Sin `service.json`, `auth.json`, `.env` ni claves privadas en el repo | Pasó |
| Simulación Stow en un HOME temporal vacío (GNU Stow 2.4.1 compilado en `/tmp`) | Limpia |
| Despliegue real en un HOME temporal | Pasó |
| Segundo despliegue idempotente | Pasó |
| Respaldo y restauración de conflicto de `~/.bashrc` en HOME temporal | Pasó |
| `--dry-run` no cambia nada ni crea carpeta de respaldo | Pasó |
| Preferencias de Ghostty: aplicar, preservar tema, idempotencia, `--remove` | Pasó |
| `./scripts/test.sh` | **53 pasaron, 0 fallaron, 1 omitido** |
| `./scripts/verify.sh --repo` | **Pasó, 1 omitido** (`stow` del sistema ausente); detectó `gh`, `opencode` y `uv` vía mise |
| `./bootstrap.sh --dry-run` | Código 0; solo lista paquetes ausentes |
| `./scripts/install-packages.sh --dry-run` | Lista `stow 7zip tree git-delta zed`; omite `uv`/`opencode` |
| `./scripts/deploy-dotfiles.sh --dry-run` | Código 0; conflictos solo `~/.bashrc` y `~/.bash_profile`; no crea respaldo |
| `./scripts/diagnose-system.sh` | Ejecución de solo lectura correcta (Omarchy, tema, NVIDIA y Bash detectados) |
| `$HOME` real intacto (`~/.dotfiles-backup` ausente) | Confirmado |

## 8. Pendientes

- `stow` real no está instalado, así que **no** se desplegaron enlaces reales y
  no se pudo ejercitar `verify.sh` en modo despliegue. Instalalo y desplegá
  cuando quieras.
- ShellCheck no está instalado. Instalalo solo si querés la comprobación más
  estricta; `test.sh` lo informa como omitido.
- `zed` no está instalado.
- No se ejecutó `gh auth login`.
- El plugin DCP de OpenCode se descarga en el primer arranque;
  `opencode plugin list` está vacío por ahora.
- No se hizo commit ni push.

## 9. Despliegue futuro (no ejecutado en esta fase)

Revisá primero y desplegá cuando estés listo:

```bash
cd ~/dotfiles

# 1. Ver el plan sin cambiar nada.
./bootstrap.sh --dry-run

# 2. Instalar paquetes ausentes y desplegar los paquetes Stow.
#    Los ~/.bashrc y ~/.bash_profile existentes se mueven a
#    ~/.dotfiles-backup/<timestamp>/ (nunca se borran).
./bootstrap.sh --yes

# 3. Opcional: preferencias personales de Ghostty (nunca el tema).
./scripts/ghostty-personal.sh --dry-run
./scripts/ghostty-personal.sh

# 4. Repetir las comprobaciones cuando quieras.
./scripts/verify.sh
./scripts/test.sh
```

El rollback está documentado en `docs/stow.md`; la reinstalación de la máquina
en `docs/reinstall.md`.

### Recuperación (después de un despliegue real)

```bash
cd ~/dotfiles

# 1. Quitar los enlaces gestionados por Stow (no borra archivos del repo).
stow -D -v bash bash-arch git opencode
command -v delta && stow -D -v git-delta

# 2. Restaurar los archivos que el despliegue respaldó.
backup="$(readlink -f ~/.dotfiles-backup/LATEST)"
cat "$backup/manifest.txt"
while IFS= read -r line; do
    orig="${line%% -> *}"
    dest="${line#* -> }"
    mkdir -p -- "$(dirname -- "$orig")"
    cp -a -- "$dest" "$orig"
done < "$backup/manifest.txt"
```

Los respaldos viven en `~/.dotfiles-backup/<timestamp>/` y nunca se versionan.

## 10. Fuera de alcance

- No se modifica Hyprland, la shell/barra de Omarchy, temas, monitores ni atajos.
- No se reemplaza la configuración base de Ghostty, Starship, Bash, Git u
  OpenCode de Omarchy.
- No se versionan `~/.ssh`, historiales, `~/.cache`, `~/.config/gh`, entornos
  virtuales, `~/.var` ni credenciales de OpenCode.
- No se modifican PAM, sysctl, repositorios ni políticas de contraseñas.
- No hay migración a Zsh/Fish; Bash es el objetivo y Omarchy ya lo usa.
- No se hacen commits ni pushes.
