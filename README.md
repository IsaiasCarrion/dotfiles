# dotfiles — Omarchy + Hyprland + Ghostty + Zed + OpenCode

Configuración personal para **Omarchy 4.5** (Arch Linux + Hyprland) administrada
con [GNU Stow](https://www.gnu.org/software/stow/). Cada carpeta de primer nivel
es un **paquete** que reproduce su ruta bajo `$HOME`; Stow crea los enlaces
simbólicos. No hay framework ni instalador opaco: Bash, pacman y Stow.

Omarchy ya administra el escritorio, Hyprland, el shell de Omarchy, los temas,
Bash, Starship, Git base y la configuración base de Ghostty/OpenCode. Este
repositorio **no duplica** esas capas: solo agrega preferencias personales y las
herramientas que no vienen en la imagen.

> **Regla de oro:** Stow se ejecuta desde la raíz del repositorio. `bootstrap.sh`
> resuelve esa ruta solo, así que podés invocarlo desde cualquier directorio.

## Inicio rápido

```bash
git clone https://github.com/IsaiasCarrion/dotfiles.git ~/dotfiles
cd ~/dotfiles

./scripts/test.sh          # pruebas seguras, no toca tu HOME
./bootstrap.sh --dry-run   # muestra todo sin cambiar nada
./bootstrap.sh             # instala lo que falta, despliega y verifica
gh auth login              # única autenticación manual necesaria
```

El bootstrap **no** cambia la shell: Omarchy ya usa Bash. Tampoco toca Ghostty,
Starship ni el escritorio.

### Requisitos

- Omarchy o una distribución Arch compatible (`/etc/os-release` con
  `ID=omarchy` o `ID_LIKE=arch`).
- `sudo` para instalar paquetes.
- Conexión a Internet para los repositorios oficiales.
- No se requiere AUR para la instalación normal. El único módulo AUR es NetBird,
  que es opcional y detecta `paru`/`yay` sin instalarlos (`yay` ya viene en
  Omarchy).

## Estructura

```
dotfiles/
├── bootstrap.sh                     # entrada: ./bootstrap.sh [opciones]
├── scripts/
│   ├── lib.sh                       # helpers (dry-run, sudo, backups, manifiestos)
│   ├── bootstrap.sh                 # orquestador: paquetes → Stow → verificación
│   ├── install-packages.sh          # pacman, solo lo ausente
│   ├── deploy-dotfiles.sh           # Stow con respaldo de conflictos
│   ├── verify.sh                    # repo (--repo) o despliegue + Omarchy
│   ├── test.sh                      # pruebas en HOMEs temporales
│   ├── diagnose-system.sh           # diagnóstico de solo lectura
│   ├── ghostty-personal.sh          # preferencias Ghostty sin tocar el tema
│   ├── install-netbird.sh           # opcional: NetBird (AUR)
│   ├── install-addy-skills.sh       # opcional, commit fijado
│   └── install-graphify.sh          # opcional, versión fijada
├── packages/
│   ├── base.txt                     # stow y utilidades del bootstrap
│   ├── common.txt                   # CLI usado por las configuraciones
│   ├── apps.txt                     # Ghostty, Zed, OpenCode, Obsidian
│   └── optional.txt                 # Go, Rust, Podman, OBS (--with-optional)
├── bash/.bashrc                     # -> ~/.bashrc (carga el rc de Omarchy)
├── bash/.bash_profile               # -> ~/.bash_profile
├── bash-arch/.config/bash/pacman.sh # -> ~/.config/bash/pacman.sh
├── git/.gitconfig                   # -> ~/.gitconfig (complemento de Omarchy)
├── git/.gitignore_global            # -> ~/.gitignore_global
├── git-delta/.config/git/delta.gitconfig  # opcional, solo si delta existe
├── opencode/.config/opencode/
│   ├── opencode.jsonc               # configuración global V2 (se fusiona)
│   ├── AGENTS.md                    # Ponytail Lite + reglas de tokens/seguridad
│   ├── dcp.jsonc                    # DCP fijado y sin auto-update
│   └── opencode.omniroute.example.jsonc
├── assets/ghostty/personal.conf     # fragmento no visual (no se stowea)
├── docs/
│   ├── omarchy.md                   # qué administra Omarchy
│   ├── ghostty.md                   # cómo se preserva el tema
│   ├── stow.md                      # despliegue por paquete
│   ├── opencode.md                  # configuración V2 y convivencia
│   ├── applications.md              # Zed, Obsidian y apps opcionales
│   ├── post-install.md              # post-instalación y módulos opcionales
│   └── reinstall.md                 # recuperar el entorno desde cero
├── AUDIT.md                         # auditoría y decisiones
├── .stowrc                          # --no-folding
└── .gitignore                       # secretos, respaldos y archivos locales
```

## Paquetes Stow

| Paquete | Qué aporta | Alcance | Requiere |
|---|---|---|---|
| `bash` | `.bashrc` que carga Omarchy + preferencias/funciones propias | Omarchy/Arch | bash |
| `bash-arch` | `pkgs`, `pkgrm`, `pacup`, `pkgclean` para pacman | Arch/Omarchy | pacman, fzf |
| `git` | Complementos de Git y `.gitignore_global` | Portable | git |
| `git-delta` | delta como pager de Git | Opcional | git-delta |
| `opencode` | Configuración global V2, DCP y reglas | Omarchy/Arch | opencode |

No hay paquetes Stow de **Ghostty**, **Starship** ni del escritorio:

- **Ghostty** y su tema son de Omarchy. Ver [docs/ghostty.md](docs/ghostty.md).
- **Starship** ya lo instala, configura e inicializa Omarchy.
- El **escritorio** (Hyprland, Omarchy shell) nunca se stowea.

## Bootstrap

```bash
./bootstrap.sh [opciones]
```

| Opción | Efecto |
|---|---|
| `--dry-run` | Muestra comandos y conflictos; no modifica nada |
| `--yes`, `-y` | No pregunta antes de mover archivos |
| `--with-optional` | Instala `packages/optional.txt` |
| `--no-packages` | No toca pacman |
| `--no-apps` | No instala `packages/apps.txt` |
| `--no-deploy` | No ejecuta Stow |
| `--no-verify` | No ejecuta las verificaciones finales |
| `--help` | Ayuda |

Pasos:

1. Verifica que sea Omarchy/Arch y que exista pacman.
2. Instala solo los paquetes ausentes de `base.txt`, `common.txt` y `apps.txt`.
3. Despliega los paquetes Stow, moviendo conflictos a `~/.dotfiles-backup/<timestamp>/`.
4. Verifica enlaces, sintaxis, JSONC, aplicaciones, tema de Omarchy y secretos.

Los pasos también se pueden ejecutar sueltos:

```bash
./scripts/install-packages.sh --dry-run
./scripts/install-packages.sh --with-optional
./scripts/deploy-dotfiles.sh --dry-run
./scripts/verify.sh --repo
./scripts/verify.sh
./scripts/diagnose-system.sh
```

### Qué instala

- **Base** (`packages/base.txt`): `stow`, `curl`, `jq`, `7zip`. El resto del
  bootstrap lo provee Omarchy.
- **CLI** (`packages/common.txt`): `bash-completion`, `ripgrep`, `fzf`, `fd`,
  `bat`, `eza`, `zoxide`, `starship`, `tmux`, `neovim`, `tree`, `python`, `uv`,
  `git-delta`. Omarchy ya trae la mayoría; el instalador omite lo presente.
- **Aplicaciones** (`packages/apps.txt`): `ghostty`, `zed`, `opencode`, `obsidian`.
- **Opcionales** (`packages/optional.txt`): `go`, `rust`, `podman`, `obs-studio`.

`gh` (GitHub CLI) **no** está en el manifiesto: Omarchy lo provee mediante mise.
Instalar `github-cli` lo duplicaría. Por la misma razón, en Omarchy el instalador
omite `opencode` y `uv` cuando ya figuran en
`/etc/mise/conf.d/omarchy-tools.toml`; los manifiestos los conservan para
instalaciones de Arch puro.

No se instala nada del escritorio. Docker ya viene con Omarchy; el repo no lo
reinstala ni lo habilita. Podman queda como opción.

### Qué protege

- **Nunca usa `stow --adopt`.**
- Si `~/.bashrc`, `~/.bash_profile`, `~/.gitconfig` o `~/.config/opencode/*.jsonc`
  ya existen como archivos reales, los **mueve** a
  `~/.dotfiles-backup/<timestamp>/` (con `manifest.txt`) antes de enlazar.
- Si un enlace apunta a otro sitio, lo trata como conflicto y lo respalda; no lo pisa.
- `--dry-run` jamás crea respaldos, instala paquetes ni escribe enlaces.
- No stowea ni edita archivos administrados por Omarchy (Ghostty, Starship,
  Hyprland, temas, escritorio).

## Shell: Bash + Omarchy

`bash/.bashrc` no reimplementa Omarchy. Carga, en orden:

1. `/usr/share/omarchy/default/bash/env-bootstrap` (`OMARCHY_PATH`, mise, PATH).
2. `/usr/share/omarchy/default/bash/rc` (aliases, funciones, mise, Starship,
   zoxide, fzf, completados).
3. Preferencias personales: PATH de Cargo/Go, historial extendido, funciones de
   venv/uv, `extract`, `mkpaths`, `gpush`, alias de seguridad y pacman.

No hay una segunda inicialización de Starship, zoxide ni fzf, y no se pisan
`EDITOR`, `BROWSER` ni `MANPAGER` (los define Omarchy). `bash/.bash_profile`
solo carga `~/.bashrc` una vez.

La shell de login la administra Omarchy (Bash). No hay `chsh` ni script de
cambio de shell.

## Git + Omarchy

Omarchy entrega `~/.config/git/config` con la identidad, los aliases base y los
ajustes generales. El paquete `git` de este repo enlaza `~/.gitconfig`, que Git
lee **después** y por eso solo contiene complementos:

- `init.defaultBranch=main`, `fetch.prune`, `rebase.autoStash`,
  `merge.conflictstyle=zdiff3` y aliases personales.
- `core.excludesfile = ~/.gitignore_global`.
- El helper portable `!gh auth git-credential` para GitHub, que evita depender
  de la ruta versionada de mise que usa Omarchy.
- Includes opcionales de `~/.config/git/delta.gitconfig` (`delta`) y
  `~/.gitconfig.local` (identidad y ajustes del equipo).
- **Nunca** fija `user.name`, `user.email` ni claves de firma.

La identidad se configura en la base de Omarchy o, si falta, en
`~/.gitconfig.local`:

```bash
git config --file ~/.gitconfig.local user.name  "Tu Nombre"
git config --file ~/.gitconfig.local user.email "tu@correo"
```

Verificación:

```bash
git config --list --show-origin | grep -E 'user\.|credential|include'
git config --get user.email
gh auth status
```

`git-delta` es opcional: si `delta` no existe, su paquete Stow no se despliega y
el include se ignora sin error. No se modifica la autenticación de Git ni de
`gh`; la única acción manual es `gh auth login`.

## Ghostty: tema de Omarchy intacto

Regla obligatoria: Ghostty conserva **exactamente** el tema de Omarchy.

- Omarchy entrega `~/.config/ghostty/config` con
  `config-file = ?"~/.local/state/omarchy/current/theme/ghostty.conf"`.
- El repo no versiona colores, paletas ni `theme =`.
- No hay paquete Stow `ghostty/`.
- `scripts/ghostty-personal.sh` es opcional y solo agrega preferencias no
  visuales (tamaño de fuente, scrollback, atajos), con respaldo y validación.

```bash
./scripts/ghostty-personal.sh --dry-run
./scripts/ghostty-personal.sh
```

Detalle: [docs/ghostty.md](docs/ghostty.md).

## Stow: uso manual

Primero simulá y después aplicá (la fase actual del repo **no** debe desplegar):

```bash
cd ~/dotfiles
stow -n -v bash bash-arch git opencode   # simulación
stow -v    bash bash-arch git opencode   # aplicar, solo cuando corresponda
command -v delta && stow -v git-delta    # opcional
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
ls -l ~/.bashrc ~/.bash_profile ~/.gitconfig
./scripts/verify.sh           # despliegue real
./scripts/verify.sh --repo    # solo el repositorio
```

### Reglas de Stow

1. Un paquete = una responsabilidad. No crees paquetes vacíos.
2. La ruta dentro del paquete es la ruta bajo `$HOME`.
3. No agregues archivos de Omarchy, secretos ni rutas privadas.
4. Agregá la fila en la tabla y la línea en la estructura de este README.
5. `.stowrc` usa `--no-folding`: enlaza archivos sueltos, no directorios enteros.
   Sin esa opción, `~/.config/git` sería un enlace al repo y todo lo que escriba
   Git terminaría versionado.

Guía completa: [docs/stow.md](docs/stow.md).

## OpenCode V2

La configuración global versionada vive en `opencode/.config/opencode/`:

- `opencode.jsonc`: modelo, plugins, límites de salida y compactación, permisos.
- `AGENTS.md`: reglas globales (Ponytail Lite, disciplina de tokens, seguridad).
- `dcp.jsonc`: Dynamic Context Pruning fijado, sin auto-update.
- `opencode.omniroute.example.jsonc`: plantilla para OmniRoute, inactiva por defecto.

Omarchy entrega `~/.config/opencode/opencode.json` (solo `update: disable`) y
`cli.json` (tema de la TUI). OpenCode carga `config.json` → `opencode.json` →
`opencode.jsonc`, así que el archivo del repo se **fusiona encima** sin
reemplazar la base de Omarchy.

Decisiones importantes:

- **Ponytail** (`opencode-ponytail@4.7.3`) es un plugin de V1 y **no** corre en
  OpenCode V2. Sus reglas **Lite** viven en `AGENTS.md`.
- **DCP** (`@tarquinen/opencode-dcp@3.2.0`) soporta la API V2 y queda fijado.
- **OmniRoute** es opcional: se activa copiando su bloque a `opencode.jsonc` y
  definiendo `OMNIROUTE_API_KEY` en el entorno. Nunca se versiona la clave.
- **Addy skills** y **Graphify** son opcionales y no se cargan por defecto.

```bash
opencode --version
opencode plugin list
```

Detalles: [docs/opencode.md](docs/opencode.md).

## Aplicaciones

| Aplicación | Integración | Instalación | Actualización |
|---|---|---|---|
| Ghostty | Omarchy (tema/config) | `apps.txt` solo si falta | `omarchy update` |
| Zed | Editor | `apps.txt` (pacman) | `omarchy update` |
| OpenCode | Agente/CLI | `apps.txt` (pacman o mise) | `omarchy update` |
| Obsidian | Notas | `apps.txt` solo si falta | `omarchy update` |
| Podman | Opcional | `--with-optional` | `omarchy update` |
| NetBird | Opcional (AUR) | `scripts/install-netbird.sh` | `install-netbird.sh --update` |
| OBS Studio | Opcional | `--with-optional` | `omarchy update` |

Detalle: [docs/applications.md](docs/applications.md).

## Escritorio (Omarchy / Hyprland)

Omarchy administra el escritorio. **No lo instales ni lo stowees desde acá.**
El repositorio no toca Hyprland, el shell de Omarchy, los temas ni los
terminales. Ver [docs/omarchy.md](docs/omarchy.md).

## Actualizaciones

```bash
cd ~/dotfiles
git pull --ff-only
./bootstrap.sh            # idempotente: solo completa lo que falte
./scripts/verify.sh

omarchy update
```

- Después de cambiar archivos de un paquete: `stow -R -v <paquete>`.
- DCP está fijado a propósito. Para actualizarlo, cambiá la versión en
  `opencode.jsonc`, revisá las notas del plugin y volvé a ejecutar
  `opencode plugin list`.
- Addy skills está fijado a un commit. Actualizá `ADDY_COMMIT` solo después de
  revisar los cambios upstream.
- No se actualiza nada automáticamente ni se reinicia el sistema.

## Configuración local (no versionada)

| Archivo | Para qué |
|---|---|
| `~/.gitconfig.local` | Nombre, correo, clave de firma y ajustes del equipo |
| `~/.bashrc.local` | Aliases con IPs, variables privadas, excepciones por máquina |
| `~/.ssh/config` | Accesos SSH |
| `~/.config/opencode/service.json` | Secreto generado por OpenCode; **nunca** se versiona |

Identidad de Git en un equipo nuevo (si Omarchy no la configuró):

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
└── .config/opencode/...
```

`~/.dotfiles-backup/LATEST` apunta al respaldo más reciente.

Volver atrás:

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
restaura lo que el script respaldó, no borra archivos ajenos al manifiesto y no
usa `stow --adopt`. Los respaldos viven fuera del repositorio y están cubiertos
por `.gitignore`.

## Seguridad

- No se versionan `service.json`, `auth.json`, `.env`, claves privadas ni
  `dcp-prompts/`.
- En `opencode.jsonc` usá `{env:VARIABLE}` o `{file:ruta}`; nunca escribas claves.
- `scripts/verify.sh` y `scripts/test.sh` buscan archivos sensibles y patrones
  obvios de secretos.
- No se descargan ni ejecutan instaladores remotos: todo sale de pacman (salvo
  Stow temporal para las pruebas y AUR para NetBird, ambos explícitos).
- No se agrega al usuario al grupo `docker` (equivale a root).
- No se aplica endurecimiento del sistema ni se modifican PAM, sysctl o repositorios.

## Problemas frecuentes

| Síntoma | Causa / solución |
|---|---|
| `existing target is neither a link nor a directory` | Archivo real en el destino. Usá `./scripts/deploy-dotfiles.sh` (respalda) o movelo a `.orig`. |
| `stow: command not found` | `sudo pacman -S stow`; el paso de paquetes lo instala. |
| `pacman failed` al instalar | Base de datos vieja: `omarchy update` y reintentar. |
| `starship`/`zoxide` no aparecen | Omarchy los inicializa desde su rc; verificá que `~/.bashrc` cargue `default/bash/rc`. |
| Ghostty cambió de tema | No stowees Ghostty. Revisá `~/.config/ghostty/config` y `./scripts/verify.sh`. |
| `ghostty +validate-config` falla | `ghostty-personal.sh` restaura el respaldo automáticamente; revisá el bloque personal. |
| `git diff` falla por `delta` | Desplegaste `git-delta` sin tener `delta`. `stow -D git-delta` o instalá `git-delta`. |
| `git` usa una ruta rara de `gh` | Omarchy apunta a una ruta de mise; el repo la reemplaza por `!gh auth git-credential`. |
| `opencode plugin list` no muestra DCP | El servicio aún no arrancó o falta red; reintentá tras el primer inicio. |
| `opencode.jsonc` no se aplica | Verificá el orden: `config.json` → `opencode.json` → `opencode.jsonc`. |
| `gh` pide autenticación | `gh auth login` (única acción manual esperada). |

## Validación

Las pruebas no tocan el `$HOME` real: despliegan en directorios temporales.

```bash
for f in bootstrap.sh scripts/*.sh bash/.bashrc bash/.bash_profile \
         bash-arch/.config/bash/pacman.sh; do bash -n "$f"; done

./scripts/test.sh          # sintaxis, JSONC, manifiestos, Stow, idempotencia, Ghostty
./scripts/verify.sh --repo # integridad del repo, sin desplegar
./scripts/verify.sh        # solo después de desplegar
./scripts/diagnose-system.sh
```

`verify.sh` comprueba que Ghostty siga usando el tema dinámico de Omarchy y que
el repo no contenga colores ni un `theme =`. `test.sh` descarga GNU Stow a un
directorio temporal si no está instalado, para poder ejecutar
`stow --simulate` sin modificar el sistema. `diagnose-system.sh` distingue GPU
detectada, driver instalado y driver activo.

`--dry-run` no instala nada y no escribe enlaces. Ver [AUDIT.md](AUDIT.md) para
el estado de las comprobaciones realizadas.
