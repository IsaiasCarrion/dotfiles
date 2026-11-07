# dotfiles — Fedora + DMS + Ghostty + OpenCode

Configuración personal de Fedora administrada con [GNU Stow](https://www.gnu.org/software/stow/).
Cada carpeta de primer nivel es un **paquete** que reproduce la ruta que tendrá bajo `$HOME`;
Stow crea los enlaces simbólicos. No hay framework ni instalador opaco: Bash, Git, DNF y Stow.

Este repositorio nació en Arch/CachyOS y fue migrado a **Fedora 45 (DNF5)**. El escritorio
objetivo es **niri + DankMaterialShell (DMS) + Ghostty + OpenCode V2**. El detalle de la auditoría
y de las decisiones está en [AUDIT.md](AUDIT.md).

> **Regla de oro:** el repositorio vive en `~/dotfiles` y Stow se ejecuta **siempre desde esa
> carpeta**. Stow usa la carpeta actual como origen, `~` como destino y lee `.stowrc`.

## Inicio rápido

```bash
git clone https://github.com/IsaiasCarrion/dotfiles.git ~/dotfiles
cd ~/dotfiles

./bootstrap.sh --dry-run   # muestra todo sin cambiar nada
./bootstrap.sh             # instala lo que falta y despliega
```

`bootstrap.sh` es idempotente: solo instala paquetes ausentes, mueve los archivos que estorban
a un respaldo y se puede volver a ejecutar sin miedo.

### Requisitos

- Fedora 45 Workstation (el script aborta si no encuentra `/etc/fedora-release`).
- `sudo` para instalar paquetes y habilitar COPR.
- Conexión a Internet.
- Acceso a los COPR `duxlabs/dms`, `duxlabs/dux-repo` y `yalter/niri` (el script los habilita
  si faltan) y a Flathub para las aplicaciones Flatpak.
- `Terra` y `RPM Fusion` son **opcionales** y solo se usan con `--with-optional`; no se habilitan
  automáticamente por ser repositorios de terceros.

## Estructura

```
dotfiles/
├── bootstrap.sh                     # entrada: ./bootstrap.sh [opciones]
├── scripts/
│   ├── lib.sh                       # helpers (dry-run, sudo, backups, manifiestos)
│   ├── bootstrap.sh                 # orquestador de los 4 pasos
│   ├── install-packages.sh          # DNF + COPR + Flatpak, solo lo ausente
│   ├── install-opencode.sh          # CLI de OpenCode V2
│   ├── deploy-dotfiles.sh           # Stow con respaldo de conflictos
│   ├── verify.sh                    # enlaces, sintaxis, JSONC, DMS/Ghostty, secretos
│   ├── install-addy-skills.sh       # opcional, commit fijado
│   └── install-graphify.sh          # opcional, versión fijada
├── packages/
│   ├── fedora.txt                   # base Fedora
│   ├── common.txt                   # CLI portable
│   ├── dms.txt                      # stack DMS (COPR)
│   ├── copr.txt                     # COPR requeridos
│   ├── flatpak.txt                  # aplicaciones Flathub
│   └── optional.txt                 # toolchains, Starship, códecs
├── bash/.bashrc                     # -> ~/.bashrc
├── bash-dnf/.config/bash/dnf.sh     # -> ~/.config/bash/dnf.sh
├── git/.gitconfig                   # -> ~/.gitconfig
├── git/.gitignore_global            # -> ~/.gitignore_global
├── git-delta/.config/git/delta.gitconfig  # opcional, solo si delta existe
├── ghostty/
│   └── .config/ghostty/config       # -> ~/.config/ghostty/config
├── assets/
│   └── ghostty/dankcolors           # fallback si DMS aún no generó el tema
├── opencode/.config/opencode/
│   ├── opencode.jsonc               # configuración global V2
│   ├── AGENTS.md                    # Ponytail Lite + reglas de tokens/seguridad
│   ├── dcp.jsonc                    # DCP fijado y sin auto-update
│   └── opencode.omniroute.example.jsonc
├── docs/
│   ├── dms.md
│   └── opencode.md
├── AUDIT.md
├── .stowrc                          # --no-folding
└── .gitignore                       # secretos, respaldos y archivos locales
```

## Paquetes

| Paquete | Qué aporta | Alcance | Requiere |
|---|---|---|---|
| `bash` | `.bashrc` portable: PATH, historial, fzf, zoxide, Starship, venvs, Git | **Portable** | bash |
| `bash-dnf` | `pkgs`, `pkgrm`, `dnfup`, `pkgclean` para Fedora | Fedora | `dnf`, `fzf` |
| `git` | `.gitconfig`, aliases, `.gitignore_global` | **Portable** | git ≥ 2.40 |
| `git-delta` | delta como pager de Git | Escritorio, opcional | `delta` |
| `ghostty` | Configuración principal de Ghostty | Escritorio | `ghostty` |
| `opencode` | Configuración global de OpenCode V2, DCP y reglas | Escritorio | OpenCode V2 |

Notas:

- `bash` activa cada herramienta opcional solo si existe; funciona en un servidor mínimo.
- `git` usa `merge.conflictstyle = zdiff3` (Git ≥ 2.35) y `help.autocorrect = prompt`
  (Git ≥ 2.40). Revisá `git --version` en equipos viejos.
- `git-delta` **solo** se despliega si `command -v delta` funciona; si no, Git fallaría al
  usarlo como pager. `deploy-dotfiles.sh` lo decide automáticamente.
- `bash-dnf` reemplazó al viejo `bash-pacman`; ya no hay comandos de `pacman`, `yay` ni AUR.

## Bootstrap

```bash
./bootstrap.sh [opciones]
```

| Opción | Efecto |
|---|---|
| `--dry-run` | Muestra comandos y conflictos; no modifica nada |
| `--yes`, `-y` | No pregunta antes de mover archivos en conflicto |
| `--with-optional` | Instala `packages/optional.txt` |
| `--no-packages` | No toca RPM/COPR/Flatpak |
| `--no-opencode` | No intenta instalar el CLI de OpenCode |
| `--no-deploy` | No ejecuta Stow |
| `--no-verify` | No ejecuta las verificaciones finales |
| `--help` | Ayuda |

Los pasos son independientes, así que también se pueden ejecutar sueltos:

```bash
./scripts/install-packages.sh --dry-run
./scripts/install-packages.sh --with-optional
./scripts/deploy-dotfiles.sh --dry-run
./scripts/verify.sh
```

### Qué instala

- **RPM base** (`packages/fedora.txt` + `packages/common.txt`): `dnf-plugins-core`, `flatpak`,
  `stow`, `git`, `curl`, `jq`, `ripgrep`, `fzf`, `fd-find`, `bat`, `eza`, `zoxide`,
  `git-delta`, `tree`, `unzip`, `7zip`, `tmux`, `neovim`, `python3`, `python3-pip`, `uv`, `gh`.
- **Stack DMS** (`packages/dms.txt`, COPR): `niri`, `dms`, `ghostty`, `quickshell`, `matugen`,
  `dux-greeter`, `dux-search`, `dux-calendar`, `dux-files`.
- **Flatpak** (`packages/flatpak.txt`): Extension Manager, Gearlever y Obsidian.
- **Opcionales** (`packages/optional.txt`): `gcc`, `make`, `golang`, `rust`, `cargo`; `starship`
  (Terra); `ffmpeg` y plugins de GStreamer (RPM Fusion). Si el repo no está habilitado, el script
  avisa y omite ese paquete en lugar de habilitar repositorios de terceros por su cuenta.

### Qué protege

- **Nunca usa `stow --adopt`.**
- Si `~/.bashrc`, `~/.gitconfig` o `~/.config/ghostty/config` ya existen como archivos reales,
  los **mueve** a `~/.dotfiles-backup/<timestamp>/` (con `manifest.txt`) antes de enlazar.
- Si un enlace apunta a otro sitio, lo trata como conflicto y lo respalda; no lo pisa.
- `--dry-run` jamás crea respaldos, instala paquetes ni escribe enlaces.
- No stowea ni edita archivos administrados por DMS (ver [docs/dms.md](docs/dms.md)).

## Stow: uso manual

Primero simulá y después aplicá:

```bash
cd ~/dotfiles
stow -n -v bash bash-dnf git ghostty opencode   # simulación
stow -v    bash bash-dnf git ghostty opencode   # aplicar
```

Combinaciones habituales:

```bash
# Escritorio Fedora completo
stow -v bash bash-dnf git ghostty opencode
command -v delta && stow -v git-delta

# Servidor o VM sin escritorio
stow -v bash git
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
ls -l ~/.bashrc ~/.gitconfig ~/.config/ghostty/config
find ~ -maxdepth 4 -type l -lname '*dotfiles/*'
stow -n -v bash bash-dnf git ghostty opencode    # no debe listar LINK/UNLINK
```

### Reglas de Stow

1. Un paquete = una responsabilidad. No crees paquetes vacíos.
2. La ruta dentro del paquete es la ruta bajo `$HOME`.
3. Antes de mover un archivo, revisá que no tenga claves, tokens ni rutas privadas.
4. Agregá la fila en la tabla y la línea en la estructura de este README.
5. `.stowrc` usa `--no-folding`: enlaza archivos sueltos, no directorios enteros. Sin esa opción,
   `~/.config/git` sería un enlace al repo y todo lo que escriba Git terminaría versionado.

## DMS (DankMaterialShell)

DMS administra su propia configuración. **No la stowees ni la edites a mano:**

- `~/.config/dms/` (settings, plugins, CSS)
- `~/.config/niri/dms/*` (`binds.kdl`, `colors.kdl`, `outputs.kdl`, `layout.kdl`, …)
- `~/.config/niri/config.kdl` y sus `include optional=true "dms/..."`
- `~/.config/ghostty/themes/dankcolors`

Los atajos de teclado actuales están en `~/.config/niri/dms/binds.kdl`; se cambian desde la
interfaz de DMS, no desde el repositorio. El repo solo aporta la configuración **principal** de
Ghostty. Si DMS todavía no generó el tema, `deploy-dotfiles.sh` copia
`assets/ghostty/dankcolors`; en cuanto DMS lo regenere, el archivo administrado gana.

Diagnóstico y detalles: [docs/dms.md](docs/dms.md).

## Ghostty

Ghostty es la terminal principal. La configuración está en `ghostty/.config/ghostty/config` y se
enlaza a `~/.config/ghostty/config`.

```bash
ghostty +validate-config
```

WezTerm **no** forma parte de la migración y no se reinstala. El tema `dankcolors` es de DMS.

## OpenCode V2

La configuración global versionada vive en `opencode/.config/opencode/`:

- `opencode.jsonc`: modelo, plugins, límites de salida y compactación, permisos.
- `AGENTS.md`: reglas globales (Ponytail Lite, disciplina de tokens, seguridad).
- `dcp.jsonc`: Dynamic Context Pruning fijado, sin auto-update.
- `opencode.omniroute.example.jsonc`: plantilla para OmniRoute, inactiva por defecto.

Decisiones importantes:

- **Ponytail** (`opencode-ponytail@4.7.3`) es un plugin de V1 y **no** corre en OpenCode V2.
  Por eso no se instala: sus reglas **Lite** viven en `AGENTS.md`, que V2 sí carga. No hay
  `~/.config/ponytail/config.json` porque sería configurado para un plugin ausente.
- **DCP** (`@tarquinen/opencode-dcp@3.2.0`) sí soporta la API de plugins V2 y queda fijado.
- **OmniRoute** es opcional: se activa copiando su bloque a `opencode.jsonc` y definiendo
  `OMNIROUTE_API_KEY` en el entorno. Nunca se versiona la clave.
- **Addy skills** y **Graphify** son opcionales y no se cargan por defecto:
  `./scripts/install-addy-skills.sh` y `./scripts/install-graphify.sh`.

```bash
~/.local/bin/opencode --version
~/.local/bin/opencode plugin list
```

Detalles, verificación y solución de problemas: [docs/opencode.md](docs/opencode.md).

## Actualizaciones

```bash
cd ~/dotfiles
git pull --ff-only
./bootstrap.sh            # idempotente: solo completa lo que falte
./scripts/verify.sh

sudo dnf upgrade --refresh
sudo flatpak update
opencode upgrade           # o: ~/.local/bin/opencode upgrade
```

- Después de cambiar archivos de un paquete: `stow -R -v <paquete>`.
- DCP está fijado a propósito. Para actualizarlo, cambiá la versión en `opencode.jsonc`,
  revisá las notas del plugin y volvé a ejecutar `opencode plugin list`.
- Addy skills está fijado a un commit. Actualizá `ADDY_COMMIT` en el script solo después de
  revisar los cambios upstream.

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
├── .gitconfig
└── .config/ghostty/config
```

`~/.dotfiles-backup/LATEST` apunta al respaldo más reciente.

Volver atrás:

```bash
cd ~/dotfiles
stow -D -v bash bash-dnf git ghostty opencode

backup="$(readlink -f ~/.dotfiles-backup/LATEST)"
cp -a "$backup/.bashrc"                    ~/.bashrc
cp -a "$backup/.gitconfig"                 ~/.gitconfig
cp -a "$backup/.config/ghostty/config"     ~/.config/ghostty/config
```

Los respaldos viven fuera del repositorio y están cubiertos por `.gitignore`.

## Seguridad

- No se versionan `service.json`, `auth.json`, `.env`, claves privadas ni `dcp-prompts/`.
- En `opencode.jsonc` usá `{env:VARIABLE}` o `{file:ruta}`; nunca escribas claves.
- `scripts/verify.sh` busca archivos sensibles y patrones obvios de secretos en los archivos
  versionados.
- Habilitar COPR, Terra o RPM Fusion es una decisión de confianza. El bootstrap solo habilita los
  COPR de DMS/Dux que el escritorio necesita; Terra y RPM Fusion quedan bajo `--with-optional` y
  solo si ya están configurados.

## Problemas frecuentes

| Síntoma | Causa / solución |
|---|---|
| `existing target is neither a link nor a directory` | Archivo real en el destino. Usá `./scripts/deploy-dotfiles.sh` (respalda) o `mv archivo archivo.orig`. |
| `stow: command not found` | `sudo dnf install stow`; el paso de paquetes lo instala. |
| Un paquete DMS no aparece | Verificá `dnf repolist --enabled`, luego `sudo dnf copr enable duxlabs/dms` y `duxlabs/dux-repo`. |
| `starship` no se instala | Requiere Terra; habilitalo desde <https://terra.fyralabs.com> o quitá `--with-optional`. |
| Códecs no se instalan | Requieren RPM Fusion Free; habilitalo desde <https://rpmfusion.org>. |
| `opencode` no está en PATH | `./scripts/install-opencode.sh` crea `~/.local/bin/opencode`; abrí una shell nueva o `source ~/.bashrc`. |
| `opencode plugin list` dice “No plugins found” | El servicio aún no arrancó o falta red para descargar DCP; `opencode plugin list` tras el primer inicio. |
| DMS cambia el tema de Ghostty | Es esperado: `dankcolors` es administrado por DMS. El fallback solo cubre el primer arranque. |
| `git diff` falla por `delta` | Desplegaste `git-delta` sin tener `delta`. `stow -D git-delta` o instalá `git-delta`. |
| El enlace dejó de ser simbólico | Una app reescribió el archivo. Revisá con `ls -l` y volvé a desplegar. |

## Antes de hacer commit

```bash
cd ~/dotfiles
git status
git diff --cached
for f in bash/.bashrc bash-dnf/.config/bash/dnf.sh scripts/*.sh bootstrap.sh; do bash -n "$f" || echo "ERROR: $f"; done
./bootstrap.sh --dry-run
git diff --cached | grep -niE '(token|secret|passw|api[_-]?key|BEGIN [A-Z ]*PRIVATE KEY)'   # debe salir vacío
```

Si algo sensible llegó a un commit, borrarlo del archivo actual **no** lo elimina del historial.

## Portable vs. escritorio

| Portable (servidores, VMs, SSH) | Fedora escritorio | Opcional |
|---|---|---|
| `bash`, `git` | `bash-dnf`, `ghostty`, `opencode`, stack DMS | `git-delta`, Addy skills, Graphify, OmniRoute |

niri, DMS, Ghostty y OpenCode se documentan acá, pero **solo sus archivos principales** se
versionan; el resto lo administra cada aplicación.
