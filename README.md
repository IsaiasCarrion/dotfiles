# dotfiles — CachyOS + DMS/Niri + Ghostty + Zed + OpenCode

Configuración personal para **CachyOS (Arch Linux)** administrada con
[GNU Stow](https://www.gnu.org/software/stow/). Cada carpeta de primer nivel es un
**paquete** que reproduce la ruta que tendrá bajo `$HOME`; Stow crea los enlaces
simbólicos. No hay framework ni instalador opaco: Bash, pacman y Stow.

El escritorio (**DMS, niri, display manager**) ya viene instalado con CachyOS y
**este repositorio no lo instala, no lo configura y no lo reemplaza**. El repo se
encarga de las herramientas, aplicaciones y configuraciones personales.

> **Regla de oro:** Stow se ejecuta desde la raíz del repositorio. `bootstrap.sh`
> resuelve esa ruta solo, así que podés invocarlo desde cualquier directorio.

## Inicio rápido

```bash
git clone https://github.com/IsaiasCarrion/dotfiles.git ~/dotfiles
cd ~/dotfiles

./bootstrap.sh --dry-run   # muestra todo sin cambiar nada
./bootstrap.sh             # instala lo que falta, despliega y verifica
gh auth login              # única autenticación manual necesaria
```

Después del bootstrap, cerrá la sesión por completo y volvé a entrar (o
reiniciá) para que Bash quede como shell de login y el entorno de systemd deje
de arrastrar `SHELL=/bin/fish`. `exec bash` cambia solo esa terminal: no
actualiza la sesión ni el entorno que usan Ghostty/DMS.

### Requisitos

- CachyOS o una distribución Arch compatible (`/etc/os-release` con
  `ID=cachyos`, `ID=arch` o `ID_LIKE=arch`).
- `sudo` para instalar paquetes y cambiar la shell de login.
- Conexión a Internet para los repositorios oficiales.
- No se requiere AUR para la instalación normal. El único módulo AUR es NetBird,
  que es opcional y detecta `paru`/`yay` sin instalarlos.

## Estructura

```
dotfiles/
├── bootstrap.sh                     # entrada: ./bootstrap.sh [opciones]
├── scripts/
│   ├── lib.sh                       # helpers (dry-run, sudo, backups, manifiestos)
│   ├── bootstrap.sh                 # orquestador: paquetes → Stow → shell → verificación
│   ├── install-packages.sh          # pacman, solo lo ausente
│   ├── deploy-dotfiles.sh           # Stow con respaldo de conflictos
│   ├── set-shell.sh                 # Bash como shell de login (solo el usuario actual)
│   ├── verify.sh                    # enlaces, sintaxis, JSONC, apps, shell y secretos
│   ├── diagnose-system.sh           # diagnóstico de solo lectura
│   ├── install-docker.sh            # opcional: Docker
│   ├── install-netbird.sh           # opcional: NetBird (AUR)
│   ├── install-addy-skills.sh       # opcional, commit fijado
│   └── install-graphify.sh          # opcional, versión fijada
├── packages/
│   ├── base.txt                     # dependencias del bootstrap
│   ├── common.txt                   # CLI usado por las configuraciones
│   ├── apps.txt                     # aplicaciones personales por defecto
│   └── optional.txt                 # toolchains, códecs y OBS (--with-optional)
├── bash/.bashrc                     # -> ~/.bashrc
├── bash/.bash_profile               # -> ~/.bash_profile
├── bash-arch/.config/bash/pacman.sh # -> ~/.config/bash/pacman.sh
├── starship/.config/starship.toml   # -> ~/.config/starship.toml
├── git/.gitconfig                   # -> ~/.gitconfig
├── git/.gitignore_global            # -> ~/.gitignore_global
├── git-delta/.config/git/delta.gitconfig  # opcional, solo si delta existe
├── ghostty/.config/ghostty/config   # -> ~/.config/ghostty/config
├── assets/ghostty/dankcolors        # fallback si DMS aún no generó el tema
├── opencode/.config/opencode/
│   ├── opencode.jsonc               # configuración global V2
│   ├── AGENTS.md                    # Ponytail Lite + reglas de tokens/seguridad
│   ├── dcp.jsonc                    # DCP fijado y sin auto-update
│   └── opencode.omniroute.example.jsonc
├── docs/
│   ├── dms.md                       # límites del escritorio administrado por CachyOS
│   ├── opencode.md                  # configuración V2, plugins y skills
│   ├── applications.md              # Zed, Obsidian y apps opcionales
│   ├── cachyos-post-install.md      # post-instalación y módulos opcionales
│   └── cachyos-reinstall.md         # recuperar el entorno desde cero
├── AUDIT.md                         # auditoría y decisiones de esta migración
├── .stowrc                          # --no-folding
└── .gitignore                       # secretos, respaldos y archivos locales
```

## Paquetes

| Paquete | Qué aporta | Alcance | Requiere |
|---|---|---|---|
| `bash` | `.bashrc` portable + `.bash_profile` de login | **Portable** | bash |
| `bash-arch` | `pkgs`, `pkgrm`, `pacup`, `pkgclean` para pacman | Arch/CachyOS | pacman, fzf |
| `starship` | Prompt compacto | **Portable** | starship |
| `git` | `.gitconfig`, aliases, `.gitignore_global` | **Portable** | git ≥ 2.40 |
| `git-delta` | delta como pager de Git | Escritorio, opcional | git-delta |
| `ghostty` | Configuración principal de Ghostty | Escritorio | ghostty |
| `opencode` | Configuración global de OpenCode V2, DCP y reglas | Escritorio | opencode |

Notas:

- `bash` activa cada herramienta opcional solo si existe; funciona en un servidor mínimo.
- `git-delta` **solo** se despliega si `command -v delta` funciona. Si no, Git fallaría
  al usarlo como pager. `deploy-dotfiles.sh` lo decide automáticamente.
- `bash-arch` reemplazó al viejo `bash-dnf`; el bootstrap no usa `dnf`, `rpm`,
  COPR ni Flatpak: los paquetes salen solo de pacman.
- No se instala Fish. La configuración equivalente vive en Bash (ver más abajo).

## Bootstrap

```bash
./bootstrap.sh [opciones]
```

| Opción | Efecto |
|---|---|
| `--dry-run` | Muestra comandos y conflictos; no modifica nada |
| `--yes`, `-y` | No pregunta antes de mover archivos o cambiar la shell |
| `--with-optional` | Instala `packages/optional.txt` |
| `--no-packages` | No toca pacman |
| `--no-apps` | No instala `packages/apps.txt` |
| `--no-deploy` | No ejecuta Stow |
| `--no-shell` | No cambia la shell de login |
| `--no-verify` | No ejecuta las verificaciones finales |
| `--help` | Ayuda |

Pasos:

1. Verifica que sea CachyOS/Arch y que exista pacman.
2. Instala solo los paquetes ausentes de `base.txt`, `common.txt` y `apps.txt`.
3. Despliega los paquetes Stow, moviendo conflictos a `~/.dotfiles-backup/<timestamp>/`.
4. Configura Bash como shell de login del usuario que ejecuta el bootstrap.
5. Verifica enlaces, sintaxis, JSONC, aplicaciones, shell y secretos.

Los pasos también se pueden ejecutar sueltos:

```bash
./scripts/install-packages.sh --dry-run
./scripts/install-packages.sh --with-optional
./scripts/deploy-dotfiles.sh --dry-run
./scripts/set-shell.sh --dry-run
./scripts/verify.sh
```

### Qué instala

- **Base** (`packages/base.txt`): `bash`, `git`, `stow`, `sudo`, `curl`,
  `ca-certificates`, `jq`, `util-linux`, `tar`, `gzip`, `bzip2`, `xz`, `zstd`,
  `unzip`, `7zip`, `findutils`.
- **CLI** (`packages/common.txt`): `bash-completion`, `ripgrep`, `fzf`, `fd`,
  `bat`, `eza`, `zoxide`, `starship`, `tree`, `tmux`, `neovim`, `python`, `uv`,
  `github-cli`, `git-delta`.
- **Aplicaciones** (`packages/apps.txt`): `ghostty`, `zed`, `opencode`, `obsidian`.
  Todas están en los repositorios oficiales de Arch/CachyOS.
- **Opcionales** (`packages/optional.txt`): `gcc`, `make`, `go`, `rust`, `ffmpeg`,
  plugins de GStreamer y `obs-studio`.

No se instala nada del escritorio: ni DMS, ni niri, ni Waybar, ni SDDM/GDM, ni
GNOME/KDE. Si CachyOS ya los tiene, quedan intactos.

### Qué protege

- **Nunca usa `stow --adopt`.**
- Si `~/.bashrc`, `~/.bash_profile`, `~/.gitconfig` o `~/.config/ghostty/config`
  ya existen como archivos reales, los **mueve** a
  `~/.dotfiles-backup/<timestamp>/` (con `manifest.txt`) antes de enlazar.
- Si un enlace apunta a otro sitio, lo trata como conflicto y lo respalda; no lo pisa.
- `--dry-run` jamás crea respaldos, instala paquetes ni escribe enlaces.
- No stowea ni edita archivos administrados por DMS/niri.

## Shell: Bash

Bash es el shell principal. `bash/.bashrc` es la configuración interactiva y
`bash/.bash_profile` carga `~/.bashrc` en shells de login. No hay una segunda
inicialización de Starship, zoxide o fzf.

Ghostty fija `command = /usr/bin/bash` en `ghostty/.config/ghostty/config`.
Eso evita que herede un `$SHELL` viejo (Fish) cuando se lanza desde una CLI o
desde una sesión anterior al cambio de shell. El `--posix` que aparece en `ps`
es la integración oficial de Ghostty: `ghostty.bash` carga los startup files y
ejecuta `set +o posix`, así que el shell interactivo **no** queda en modo POSIX.

`scripts/set-shell.sh`:

1. comprueba que Bash exista y esté en `/etc/shells` (lo agrega si falta);
2. lee la shell actual del usuario;
3. solo modifica al usuario que ejecuta el instalador (`SUDO_USER` si se usó sudo);
4. informa que hay que cerrar sesión para aplicar el cambio.

### Migración desde Fish

La auditoría no encontró **ningún** archivo Fish versionado en este repositorio
ni en su historial (`config.fish`, `conf.d/`, `functions/`, variables
universales). Por eso no hubo funciones del repo que migrar: las capacidades
equivalentes ya están en Bash (PATH idempotente, aliases, funciones de venv/uv,
historial, autocompletado, fzf, zoxide y Starship). Fish **no** se instala ni se
configura.

Un equipo CachyOS puede tener configuración local en `~/.config/fish` que no
está versionada. El bootstrap **no la lee, no la modifica y no la borra**;
`verify.sh` solo avisa si existe. Antes de eliminar Fish, comparala a mano:

```bash
ls -la ~/.config/fish
grep -RInE 'alias|function|set -gx|fish_add_path|starship init|zoxide init|fzf' ~/.config/fish
```

Después de `./scripts/set-shell.sh`, cerrá sesión y comprobá:

```bash
echo "$SHELL"
ps -p $$ -o comm=
getent passwd "$USER"
```

Zsh queda **fuera de esta etapa**: no se instala ni se configura. Una migración
Bash → Zsh se auditará por separado.

## Stow: uso manual

Primero simulá y después aplicá:

```bash
cd ~/dotfiles
stow -n -v bash bash-arch git ghostty opencode starship   # simulación
stow -v    bash bash-arch git ghostty opencode starship   # aplicar
```

Combinaciones habituales:

```bash
# Escritorio completo
stow -v bash bash-arch git ghostty opencode starship
command -v delta && stow -v git-delta

# Servidor o VM sin escritorio
stow -v bash git starship
```

Rehacer enlaces después de agregar o renombrar archivos dentro de un paquete:

```bash
stow -R -v bash
```

Retirar un paquete (borra solo los enlaces, nunca los archivos del repo):

```bash
stow -D -v git-delta
```

Verificar:

```bash
ls -l ~/.bashrc ~/.bash_profile ~/.gitconfig ~/.config/ghostty/config
stow -n -v bash bash-arch git ghostty opencode starship    # no debe listar LINK/UNLINK
```

### Reglas de Stow

1. Un paquete = una responsabilidad. No crees paquetes vacíos.
2. La ruta dentro del paquete es la ruta bajo `$HOME`.
3. Antes de mover un archivo, revisá que no tenga claves, tokens ni rutas privadas.
4. Agregá la fila en la tabla y la línea en la estructura de este README.
5. `.stowrc` usa `--no-folding`: enlaza archivos sueltos, no directorios enteros.
   Sin esa opción, `~/.config/git` sería un enlace al repo y todo lo que escriba
   Git terminaría versionado.

## OpenCode V2

La configuración global versionada vive en `opencode/.config/opencode/`:

- `opencode.jsonc`: modelo, plugins, límites de salida y compactación, permisos.
- `AGENTS.md`: reglas globales (Ponytail Lite, disciplina de tokens, seguridad).
- `dcp.jsonc`: Dynamic Context Pruning fijado, sin auto-update.
- `opencode.omniroute.example.jsonc`: plantilla para OmniRoute, inactiva por defecto.

El paquete `opencode` de los repositorios oficiales provee el CLI V2. No se usa
Terra, RPM ni instaladores remotos.

Decisiones importantes:

- **Ponytail** (`opencode-ponytail@4.7.3`) es un plugin de V1 y **no** corre en
  OpenCode V2. Sus reglas **Lite** viven en `AGENTS.md`. No hay configuración
  muerta de Ponytail.
- **DCP** (`@tarquinen/opencode-dcp@3.2.0`) soporta la API V2 y queda fijado.
- **OmniRoute** es opcional: se activa copiando su bloque a `opencode.jsonc` y
  definiendo `OMNIROUTE_API_KEY` en el entorno. Nunca se versiona la clave.
- **Addy skills** y **Graphify** son opcionales y no se cargan por defecto.

```bash
opencode --version
opencode plugin list
```

Detalles y solución de problemas: [docs/opencode.md](docs/opencode.md).

## Aplicaciones

| Aplicación | Integración | Instalación | Actualización |
|---|---|---|---|
| Ghostty | Config principal | `bootstrap.sh` (pacman) | `sudo pacman -Syu` |
| Zed | Editor | `bootstrap.sh` (pacman) | `sudo pacman -Syu` |
| OpenCode | Agente/CLI | `bootstrap.sh` (pacman) | `sudo pacman -Syu` |
| Obsidian | Notas | `bootstrap.sh` (pacman) | `sudo pacman -Syu` |
| Docker | Opcional | `scripts/install-docker.sh` | `sudo pacman -Syu` |
| NetBird | Opcional (AUR) | `scripts/install-netbird.sh` | `scripts/install-netbird.sh --update` |
| OBS Studio | Opcional | `./bootstrap.sh --with-optional` | `sudo pacman -Syu` |

Detalle: [docs/applications.md](docs/applications.md).

## Escritorio (DMS / niri)

CachyOS administra el escritorio. **No lo instales ni lo stowees desde acá.**
El repositorio solo aporta la configuración principal de Ghostty y un tema de
fallback. Ver [docs/dms.md](docs/dms.md).

## Actualizaciones

```bash
cd ~/dotfiles
git pull --ff-only
./bootstrap.sh            # idempotente: solo completa lo que falte
./scripts/verify.sh

sudo pacman -Syu
```

- Después de cambiar archivos de un paquete: `stow -R -v <paquete>`.
- DCP está fijado a propósito. Para actualizarlo, cambiá la versión en
  `opencode.jsonc`, revisá las notas del plugin y volvé a ejecutar
  `opencode plugin list`.
- Addy skills está fijado a un commit. Actualizá `ADDY_COMMIT` en el script solo
  después de revisar los cambios upstream.
- No se actualiza nada automáticamente ni se reinicia el sistema.

## Configuración local (no versionada)

| Archivo | Para qué |
|---|---|
| `~/.gitconfig.local` | Nombre, correo, clave de firma y ajustes del equipo |
| `~/.bashrc.local` | Aliases con IPs, variables privadas, excepciones por máquina |
| `~/.ssh/config` | Accesos SSH |
| `~/.config/opencode/service.json` | Secreto generado por OpenCode; **nunca** se versiona |

Identidad de Git en un equipo nuevo:

```bash
git config --file ~/.gitconfig.local user.name  "Tu Nombre"
git config --file ~/.gitconfig.local user.email "tu@correo"
```

## Respaldos y vuelta atrás

Cada despliegue con conflictos crea:

```
~/.dotfiles-backup/<timestamp>/
├── manifest.txt          # origen -> respaldo
├── .bashrc
├── .bash_profile
├── .gitconfig
└── .config/ghostty/config
```

`~/.dotfiles-backup/LATEST` apunta al respaldo más reciente.

Volver atrás (quitar los enlaces no toca el repositorio; después se restauran
solo los archivos que el manifiesto respaldó):

```bash
cd ~/dotfiles
stow -D -v bash bash-arch git ghostty opencode starship
# si estaba desplegado:
stow -D -v git-delta

backup="$(readlink -f ~/.dotfiles-backup/LATEST)"
while IFS= read -r line; do
    orig="${line%% -> *}"
    dest="${line#* -> }"
    mkdir -p -- "$(dirname -- "$orig")"
    cp -a -- "$dest" "$orig"
done < "$backup/manifest.txt"
```

El manifiesto tiene el formato `origen -> respaldo`. Revisalo antes de copiar:
`cat "$backup/manifest.txt"`. El procedimiento sobrescribe el contenido actual
de esas rutas, no borra archivos que no estén en el manifiesto y no usa
`stow --adopt`.

Los respaldos viven fuera del repositorio y están cubiertos por `.gitignore`.

## Seguridad

- No se versionan `service.json`, `auth.json`, `.env`, claves privadas ni `dcp-prompts/`.
- En `opencode.jsonc` usá `{env:VARIABLE}` o `{file:ruta}`; nunca escribas claves.
- `scripts/verify.sh` busca archivos sensibles y patrones obvios de secretos.
- No se descargan ni ejecutan instaladores remotos: todo sale de pacman.
- No se agrega al usuario al grupo `docker` (equivale a root).
- No se aplica endurecimiento del sistema ni se modifican PAM, sysctl o repositorios.

## Problemas frecuentes

| Síntoma | Causa / solución |
|---|---|
| `existing target is neither a link nor a directory` | Archivo real en el destino. Usá `./scripts/deploy-dotfiles.sh` (respalda) o movelo a `.orig`. |
| `stow: command not found` | `sudo pacman -S stow`; el paso de paquetes lo instala. |
| `pacman failed` al instalar | Base de datos vieja: `sudo pacman -Syu` y reintentar. |
| Bash no es la shell al abrir una terminal | `./scripts/set-shell.sh`; después cerrá sesión y volvé a entrar. |
| `starship`/`zoxide` no aparecen | Verificá que estén instalados y que `~/.bashrc` sea el enlace al repo. |
| `git diff` falla por `delta` | Desplegaste `git-delta` sin tener `delta`. `stow -D git-delta` o instalá `git-delta`. |
| DMS cambia el tema de Ghostty | Es esperado: `dankcolors` es administrado por DMS. El fallback solo cubre el primer arranque. |
| `ghostty +show-config` muestra `/bin/fish` | `$SHELL` de la sesión está viejo. El repo fija `command = /usr/bin/bash`; cerrá sesión por completo y volvé a entrar. |
| `ps` muestra `bash --posix` | Es la integración de shell de Ghostty; `ghostty.bash` ejecuta `set +o posix`. `ps -p $$ -o comm=` debe mostrar `bash`. |
| `diagnose-system.sh` decía que no había driver NVIDIA | Corregido: usa `nvidia-smi`, `/sys/module/nvidia` y `lspci -k`, no solo paquetes o `lsmod`. |
| `opencode plugin list` no muestra DCP | El servicio aún no arrancó o falta red; reintentá tras el primer inicio. |
| Un AppImage no arranca | Verificá `/dev/fuse` y `fuse2`/`fuse3`. |
| `gh` pide autenticación | `gh auth login` (única acción manual esperada). |

## Validación

Antes de dar por buena una instalación:

```bash
for f in bootstrap.sh scripts/*.sh bash/.bashrc bash/.bash_profile \
         bash-arch/.config/bash/pacman.sh; do bash -n "$f"; done
if command -v shellcheck >/dev/null; then shellcheck -x bootstrap.sh scripts/*.sh; fi
./bootstrap.sh --dry-run
./scripts/verify.sh
./scripts/diagnose-system.sh
```

`verify.sh` comprueba la configuración efectiva de Ghostty (`command` Bash y
`theme = dankcolors`), no solo que el archivo exista. `diagnose-system.sh`
distingue GPU detectada, driver instalado y driver activo.

`--dry-run` no instala nada y no escribe enlaces. La verificación real requiere
una sesión CachyOS/Arch con los paquetes instalados. Ver [AUDIT.md](AUDIT.md) para
el estado de las comprobaciones realizadas en esta auditoría.
