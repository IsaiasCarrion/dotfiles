# Auditoría y migración Arch → Fedora

Fecha: 2026-11-07
Equipo auditado: Fedora 45 Workstation, DNF 5.4.7, niri 26.04, DMS 2.1.1,
Ghostty 1.4.0, OpenCode 2.2.6.

Este documento registra qué se encontró, qué se cambió y por qué. El objetivo fue preservar la
configuración que ya funcionaba y reemplazar la administración basada en Arch/pacman por un
sistema reproducible con Fedora/DNF, GNU Stow y un único comando de arranque.

## 1. Estado inicial

### Repositorio

- Remoto: `https://github.com/IsaiasCarrion/dotfiles` (rama `master`).
- Árbol limpio, último commit `faa036e`.
- Paquetes existentes: `bash`, `bash-pacman`, `git`, `git-delta`.
- `README.md` describía únicamente Arch/CachyOS y `pacman`.
- No había scripts de instalación, manifiestos de paquetes ni documentación de Fedora.
- No había configuración de OpenCode, Ghostty ni DMS versionada.

### Sistema

- Fedora 45 Workstation con DNF5.
- Escritorio niri + DMS 2.1.1; `dms` administra `~/.config/dms` y `~/.config/niri/dms`.
- Ghostty 1.4.0 como terminal principal; `~/.config/ghostty/config` era un archivo real.
- OpenCode instalado como RPM `opencode-2.2.6-1.x86_64`; el CLI ejecutable vive en
  `/opt/OpenCode/resources/opencode-cli` y no estaba en `PATH`.
- `~/.config/opencode/` solo contenía `service.json` (contraseña generada). No había
  `opencode.jsonc`, `AGENTS.md`, plugins, skills ni configuración de Ponytail/DCP/Graphify.
- `~/.bashrc` y `~/.gitconfig` eran archivos reales, no enlaces a dotfiles.
- No existía `~/.gitignore_global`.
- COPR habilitados: `duxlabs/dms`, `duxlabs/dux-repo`, `yalter/niri`.
- Repositorios adicionales habilitados: RPM Fusion, Terra, Google Chrome, Flathub.
- Flatpak instalados: Extension Manager, Gearlever y Obsidian (sistema, Flathub).
- Faltaban: `stow`, `fzf`, `fd`, `eza`, `zoxide`, `starship`, `delta`, `ripgrep`, `uv`,
  `node`, `pip`, `neovim`.

### Respaldos

Antes de tocar nada se creó:

```
~/.dotfiles-backup/20261107-180945/   (modo 700, fuera del repositorio)
~/.dotfiles-backup/LATEST -> 20261107-180945
```

Incluye `.bashrc`, `.gitconfig`, `~/.config/ghostty/config`, `~/.config/opencode/service.json`,
`~/.config/niri/config.kdl` y los archivos de DMS relevantes.

## 2. Cambios realizados

### Shell

- `bash-pacman/` → `bash-dnf/`.
- `pacman.sh` → `dnf.sh` con `pkgs` (buscar/instalar con fzf), `pkgrm`, `dnfup` y `pkgclean`.
- `.bashrc` ahora:
  - carga `/etc/bashrc` si existe (Fedora);
  - carga fragmentos de `~/.bashrc.d/*`;
  - agrega `~/.local/bin` y `~/go/bin` al `PATH`;
  - mantiene todas las funciones portables (venvs, Git, archivos, etc.);
  - carga `~/.config/bash/dnf.sh` solo si existe.
- No se agregaron Fish, Zsh ni frameworks nuevos. Bash sigue siendo el shell.

### Git

- Se conservó `.gitconfig` y `.gitignore_global`.
- Se limpiaron los helpers de credencial para que funcionen con `gh` sin rutas absolutas.
- `git-delta` sigue siendo opcional y solo se despliega si `delta` está instalado.

### Ghostty

- Se versionó la configuración principal en `ghostty/.config/ghostty/config`.
- El tema `dankcolors` es generado por DMS; el repo solo guarda un fallback en
  `assets/ghostty/dankcolors`.
- WezTerm no se migró ni se reinstaló.

### OpenCode

- Se creó `opencode.jsonc` con forma nativa V2: `model`, `plugins`, `tool_output`,
  `compaction`, `watcher` y `permissions`.
- Modelo por defecto: `opencode/big-pickle` (disponible sin configurar proveedores).
- DCP fijado a `@tarquinen/opencode-dcp@3.2.0`, con `autoUpdate: false`.
- Ponytail: el plugin `opencode-ponytail@4.7.3` es V1-only y no corre en V2. Se trasladó su
  ruleset **Lite** a `AGENTS.md` y se eliminó la configuración muerta `~/.config/ponytail`.
- OmniRoute queda como plantilla inactiva (`opencode.omniroute.example.jsonc`), sin claves.
- `service.json`, `auth.json`, `.env` y material de claves quedan fuera de Git.

### Paquetes

Manifiestos nuevos, separados por origen:

- `packages/fedora.txt`: base Fedora.
- `packages/common.txt`: CLI portable.
- `packages/dms.txt`: stack DMS desde COPR.
- `packages/copr.txt`: COPR necesarios.
- `packages/flatpak.txt`: aplicaciones Flathub existentes.
- `packages/optional.txt`: toolchains, Starship (Terra) y códecs (RPM Fusion).

El paso de paquetes instala **solo lo ausente**, no habilita Terra/RPM Fusion automáticamente y
no reinstala lo que ya está.

### Bootstrap y verificación

- `bootstrap.sh` + `scripts/`:
  - detección de Fedora;
  - `--dry-run`, `--yes`, `--with-optional` y pasos desactivables;
  - instalación idempotente de RPM, COPR y Flatpak;
  - enlace del CLI de OpenCode V2;
  - despliegue con Stow y respaldo de conflictos;
  - verificación de enlaces, sintaxis Bash, JSONC, Ghostty, niri, plugins y secretos.
- Nunca se usa `stow --adopt`.
- `.stowrc` mantiene `--no-folding`.

### Documentación

- `README.md` reescrito para Fedora, DMS, Ghostty y OpenCode.
- `docs/dms.md`: límites de DMS y archivos que no se deben tocar.
- `docs/opencode.md`: configuración V2, plugins, skills opcionales y secretos.
- Este `AUDIT.md`.

## 3. Decisiones y justificaciones

| Decisión | Motivo |
|---|---|
| Fedora/DNF en lugar de Arch/pacman | El equipo real es Fedora 45; se elimina AUR/yay/paru. |
| RPM, COPR, Flatpak y standalone separados | Permite auditar el origen y evita mezclar terceros con la base. |
| Stow con `--no-folding` | Evita que directorios completos (`~/.config/git`) terminen dentro del repo. |
| Respaldar en vez de pisar | Requisito de seguridad; los archivos existentes se conservan. |
| No stowear DMS | DMS regenera `~/.config/dms`, `~/.config/niri/dms` y el tema de Ghostty. |
| Ghostty principal, sin WezTerm | Ghostty ya era la terminal del escritorio. |
| Ponytail Lite vía `AGENTS.md` | El plugin es V1-only; el ruleset sí es compatible con V2. |
| DCP fijado | Evita actualizaciones silenciosas de un plugin que toca el contexto. |
| Graphify/Addy opcionales y fijados | No se cargan si no aportan; el pin hace la instalación reproducible. |
| No instalar OpenCode de Terra | Terra publica V1 (1.18.18); el equipo ya tiene V2.2.6. |

## 4. Verificación

Comandos previstos después del despliegue:

```bash
cd ~/dotfiles
./scripts/verify.sh
bash -n bash/.bashrc bash-dnf/.config/bash/dnf.sh
stow -n -v bash bash-dnf git ghostty opencode
ghostty +validate-config
niri validate -c ~/.config/niri/config.kdl
~/.local/bin/opencode plugin list
```

`scripts/verify.sh` también parsea los JSONC, revisa que los enlaces apunten al repo y busca
archivos/patrones sensibles.

## 5. Acciones pendientes

1. Instalar los paquetes ausentes con `./bootstrap.sh` (requiere contraseña de `sudo`).
2. Desplegar los paquetes Stow; el primer despliegue moverá `.bashrc`, `.gitconfig` y
   `~/.config/ghostty/config` al respaldo.
3. Ejecutar `./scripts/verify.sh` y `ghostty +validate-config`.
4. Opcional: `./scripts/install-addy-skills.sh`, `./scripts/install-graphify.sh` y activar
   OmniRoute cuando el gateway esté disponible.

## 6. Fuera de alcance

- No se versionan `~/.ssh`, `~/.bash_history`, `~/.cache`, `~/.config/gh`, `~/venvs`, `~/.var`
  ni secretos de OpenCode.
- No se migran configuraciones administradas por DMS ni atajos de teclado.
- No se reinstalan aplicaciones que no estaban presentes antes de la auditoría.
