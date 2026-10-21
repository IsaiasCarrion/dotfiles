# dotfiles

Configuración personal de Linux administrada con [GNU Stow](https://www.gnu.org/software/stow/).
Cada carpeta de primer nivel es un **paquete** que reproduce la ruta que tendrá bajo `$HOME`;
Stow crea los enlaces simbólicos. Sin frameworks, sin instalador: solo Bash, Git y Stow.

> **Regla de oro:** el repositorio vive en `~/dotfiles` y Stow se ejecuta **siempre desde esa carpeta**.
> Stow usa la carpeta actual como origen y su directorio padre (`~`) como destino, y lee `.stowrc` desde ahí.

## Estructura

```
dotfiles/
├── .stowrc                         # --no-folding (ver "Evitar conflictos")
├── .gitignore                      # respaldos y archivos locales fuera del repo
├── README.md
├── bash/
│   └── .bashrc                     -> ~/.bashrc
├── bash-pacman/
│   └── .config/bash/pacman.sh      -> ~/.config/bash/pacman.sh
├── git/
│   ├── .gitconfig                  -> ~/.gitconfig
│   └── .gitignore_global           -> ~/.gitignore_global
└── git-delta/
    └── .config/git/delta.gitconfig -> ~/.config/git/delta.gitconfig
```

## Paquetes

| Paquete | Qué hace | Alcance | Requiere |
|---|---|---|---|
| `bash` | `.bashrc`: PATH, historial, fzf, zoxide, Starship, funciones y aliases | **Portable** (PC, notebook, VMs, servidores) | bash |
| `bash-pacman` | `pacs` y `pacrm` (navegar, instalar y quitar paquetes con fzf) | Solo Arch/CachyOS | `pacman`, `fzf`, `sudo` |
| `git` | `.gitconfig`, aliases y `.gitignore_global` | **Portable** | git ≥ 2.40 (ver nota) |
| `git-delta` | delta como pager de Git | Escritorio, **opcional** | `delta` instalado |

Notas:

- `bash` activa cada herramienta opcional solo si existe, así que funciona igual en un servidor mínimo.
- `git` usa `merge.conflictstyle = zdiff3` (Git ≥ 2.35) y `help.autocorrect = prompt` (Git ≥ 2.40).
  Revisá `git --version` en servidores viejos antes de desplegarlo.
- `git-delta`: desplegalo **solo si** `command -v delta` encuentra el programa; si no, Git falla al usarlo como pager.

## Dependencias

- **Obligatorias:** `bash`, `git`, `stow`.
- **Opcionales** (el `.bashrc` las detecta; sin ellas simplemente no se activan):
  `fzf`, `fd`, `bat`, `eza`, `zoxide`, `starship`, `uv`, `gh`, `zeditor` (Zed), `delta`.
- Las fuentes (JetBrainsMono Nerd Font) se instalan aparte: `eza --icons` y Starship las necesitan para verse bien.

## Instalar GNU Stow

```bash
sudo pacman -S stow          # Arch / CachyOS
stow --version
```

En otras distribuciones el paquete también se llama `stow` (`apt`, `dnf`), pero esos comandos no están probados acá.

## Desplegar, simular, retirar

Primero **simulá** (no modifica nada) y recién después aplicá:

```bash
cd ~/dotfiles
stow -n -v bash bash-pacman git     # simulación
stow -v bash bash-pacman git        # aplicar
```

Combinaciones habituales:

```bash
# PC de escritorio / notebook con Arch o CachyOS
stow -v bash bash-pacman git
# Solo si delta está instalado:
command -v delta && stow -v git-delta

# Servidor o VM (sin pacman, sin escritorio)
stow -v bash git
```

Retirar un paquete (solo borra los enlaces, nunca tus archivos del repo):

```bash
stow -D -v git-delta
```

Rehacer los enlaces después de agregar o renombrar archivos en un paquete:

```bash
stow -R -v bash
```

## Verificar los enlaces

```bash
ls -l ~/.bashrc ~/.gitconfig ~/.gitignore_global ~/.config/bash/pacman.sh
find ~ -maxdepth 4 -type l -lname '*dotfiles/*'     # todos los enlaces que apuntan al repo
find ~ -maxdepth 4 -xtype l                         # enlaces rotos (no debería listar los tuyos)
stow -n -v bash bash-pacman git                     # tras desplegar, no debe mostrar LINK ni UNLINK
bash -n ~/.bashrc && echo OK
```

Probar los paquetes en un `$HOME` vacío, sin tocar el real:

```bash
cd ~/dotfiles
T=$(mktemp -d)
stow -n -v -t "$T" bash git        # simular
stow -v -t "$T" bash git
HOME="$T" bash -i                  # abrir una shell de prueba
```

## Primer despliegue en un equipo con archivos existentes

Si ya existen `~/.bashrc` o `~/.gitconfig` como archivos reales, Stow se niega a pisarlos
(`existing target is neither a link nor a directory`). Es lo esperado:

```bash
# 1. Crear la identidad local ANTES de mover el gitconfig (lo lee del archivo actual):
git config --file ~/.gitconfig.local user.name  "$(git config --file ~/.gitconfig user.name)"
git config --file ~/.gitconfig.local user.email "$(git config --file ~/.gitconfig user.email)"

# 2. Mover (no borrar) los archivos actuales:
mv ~/.bashrc ~/.bashrc.orig
mv ~/.gitconfig ~/.gitconfig.orig

# 3. Simular y desplegar:
cd ~/dotfiles
stow -n -v bash git && stow -v bash git
```

Volver atrás:

```bash
cd ~/dotfiles && stow -D bash git
mv ~/.bashrc.orig ~/.bashrc && mv ~/.gitconfig.orig ~/.gitconfig
```

## Agregar una nueva configuración

Ejemplo con Starship (`~/.config/starship.toml`):

```bash
cd ~/dotfiles
mkdir -p starship/.config
mv ~/.config/starship.toml starship/.config/
stow -n -v starship && stow -v starship
ls -l ~/.config/starship.toml
```

Reglas:

1. Un paquete = una responsabilidad. No crees paquetes vacíos ni uno por cada programa instalado.
2. La ruta dentro del paquete es la ruta bajo `$HOME`.
3. Antes de mover un archivo, revisalo: no debe contener claves, tokens ni rutas privadas.
4. Agregá la fila en la tabla de paquetes y la línea en "Estructura" de este README.

## Evitar conflictos

- **`--adopt` está prohibido:** mueve tu archivo al repo y pisa la versión versionada.
- **Archivo real en el destino:** renombralo (`mv x x.orig`), volvé a simular y recién ahí desplegá.
- **Enlace que apunta a otro lado:** Stow no lo toca. Revisalo con `ls -l` y decidí a mano.
- **`.stowrc` con `--no-folding`:** hace que Stow enlace archivos sueltos y no directorios enteros.
  Sin esa opción, un directorio como `~/.config/git` pasaría a ser un enlace al repo y todo lo que
  Git o una aplicación escriba ahí terminaría dentro del repositorio.
- **Aplicaciones que reescriben su configuración:** algunas reemplazan el archivo en vez de editarlo,
  lo que rompe el enlace (queda un archivo suelto y el repo, desactualizado). Después de editar con
  una aplicación, confirmá con `ls -l` que sigue siendo un enlace.

## Configuración local (no versionada)

Estos archivos viven solo en cada equipo y están cubiertos por `.gitignore`:

| Archivo | Para qué |
|---|---|
| `~/.gitconfig.local` | Nombre, correo, clave de firma, ajustes propios del equipo |
| `~/.bashrc.local` | Aliases con IPs/usuarios, variables privadas, excepciones por máquina |
| `~/.ssh/config` | Accesos SSH (preferible a un alias de Bash) |

Identidad de Git en un equipo nuevo:

```bash
git config --file ~/.gitconfig.local user.name  "Tu Nombre"
git config --file ~/.gitconfig.local user.email "tu@correo"
```

Acceso SSH con nombre corto (`ssh server`), sin datos en el repo:

```
Host server
    HostName <ip-o-dominio>
    User <usuario>
```

Git ignora sin error los `include` cuyo archivo no existe, así que ninguno de estos archivos es obligatorio.

## Antes de hacer commit

```bash
cd ~/dotfiles
git status
git diff --cached                                  # leer TODO lo que se va a subir
for f in bash/.bashrc bash-pacman/.config/bash/pacman.sh; do bash -n "$f" || echo "ERROR: $f"; done
shellcheck -s bash -e SC1091 bash/.bashrc bash-pacman/.config/bash/pacman.sh   # si lo tenés
stow -n -v bash bash-pacman git                    # no debe listar cambios
git diff --cached | grep -niE '(token|secret|passw|api[_-]?key|BEGIN [A-Z ]*PRIVATE KEY)'   # debe salir vacío
```

Si algo sensible llegó a un commit, borrarlo del archivo actual **no** lo elimina del historial de Git.

## Portable vs. escritorio

| Portable (servidores, VMs, SSH) | Solo Arch/CachyOS | Solo escritorio |
|---|---|---|
| `bash`, `git` | `bash-pacman` | `git-delta` |

Niri, Dank Material Shell y Zed **no** forman parte del repositorio por ahora.

## Fuera del repositorio (nunca versionar)

`~/.bash_history`, `~/.cache/`, `~/.config/gh/` (guarda el token), `~/.ssh/`,
`~/.local/share/zoxide/` y `~/.local/share/atuin/`, `~/venvs`, `~/.var`, `~/.zshrc` y su historial.
