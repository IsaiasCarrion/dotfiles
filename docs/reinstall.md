# Reinstalación limpia de Omarchy

Objetivo: recuperar el entorno de trabajo desde una instalación limpia de
Omarchy usando este repositorio, sin duplicar lo que Omarchy ya administra.

## 0. Antes de borrar el sistema

Guardá fuera del equipo o en una partición aparte:

- El repositorio `~/dotfiles` (o `git push` de los cambios que quieras conservar).
- `~/.gitconfig.local` y `~/.bashrc.local`.
- `~/.ssh/` (claves y `config`), sin subirlas a ningún repositorio.
- `~/.config/opencode/service.json` (secreto local, nunca versionado).
- Vaults de Obsidian y cualquier archivo de `~/.dotfiles-backup/` que quieras
  conservar.

No es necesario respaldar Hyprland, el shell de Omarchy, los temas ni la
configuración de Ghostty/Starship: Omarchy los regenera.

## 1. Instalar Omarchy

1. Instalación normal de Omarchy (Hyprland + Omarchy shell).
2. Primer arranque y actualización:

```bash
omarchy update
omarchy version
cat /etc/os-release        # ID=omarchy
```

3. Comprobá que Bash sea tu shell de login (Omarchy lo usa por defecto):

```bash
getent passwd "$USER" | cut -d: -f7
```

## 2. Recuperar el repositorio

```bash
git clone https://github.com/IsaiasCarrion/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Si traés un backup local, copiá el contenido a `~/dotfiles` en lugar de clonar.
Revisá `git status` antes de seguir.

## 3. Bootstrap

Primero simulá; después aplicá:

```bash
./bootstrap.sh --dry-run
./bootstrap.sh
```

Pasos que ejecuta:

1. Paquetes oficiales que falten (`install-packages.sh`).
2. Despliegue Stow con respaldo de conflictos (`deploy-dotfiles.sh`).
3. Verificación (`verify.sh`).

Opciones útiles:

```bash
./bootstrap.sh --yes              # sin preguntas de respaldo
./bootstrap.sh --with-optional    # Go, Rust, Podman, OBS
./bootstrap.sh --no-apps          # no instala Ghostty/Zed/OpenCode/Obsidian
./bootstrap.sh --no-deploy        # solo paquetes
./bootstrap.sh --no-verify        # sin verificación final
```

No hay paso de `chsh`: Omarchy ya usa Bash.

## 4. Autenticación de GitHub

```bash
gh auth login
```

Omarchy provee `gh` a través de mise. El helper de `git/.gitconfig` usa
`gh auth git-credential`; si preferís el helper de Omarchy, quitá ese bloque.

## 5. Restaurar configuración local

Estos archivos no están en el repositorio:

```bash
cp /ruta/backup/gitconfig.local   ~/.gitconfig.local
cp /ruta/backup/bashrc.local      ~/.bashrc.local
cp -a /ruta/backup/ssh            ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config ~/.ssh/id_* 2>/dev/null || true
```

Identidad de Git (si no vino en la configuración de Omarchy):

```bash
git config --file ~/.gitconfig.local user.name  "Tu Nombre"
git config --file ~/.gitconfig.local user.email "tu@correo"
```

Obsidian: abrí los vaults desde la aplicación; el repositorio no los crea ni los
modifica.

## 6. Preferencias personales de Ghostty (opcional)

El tema queda intacto. Si querés aplicar tamaño de fuente, scrollback y atajos:

```bash
./scripts/ghostty-personal.sh --dry-run
./scripts/ghostty-personal.sh
```

Ver [ghostty.md](ghostty.md).

## 7. Módulos opcionales

```bash
./scripts/install-packages.sh --with-optional   # Podman, Go, Rust, OBS
./scripts/install-netbird.sh                    # NetBird desde AUR (yay/paru)
./scripts/install-addy-skills.sh                # skills de OpenCode
./scripts/install-graphify.sh                   # Graphify
```

Ninguno se ejecuta solo. Revisá cada `--dry-run` antes de aplicar.

## 8. Verificación final

```bash
./scripts/test.sh        # pruebas en HOMEs temporales, no toca el real
./scripts/verify.sh      # despliegue y entorno Omarchy
./scripts/diagnose-system.sh

ghostty +validate-config
starship --version
opencode --version
omarchy version
```

## Checklist final

- [ ] Omarchy actualizado y `omarchy version` responde.
- [ ] Repositorio clonado en `~/dotfiles`.
- [ ] `./bootstrap.sh` terminó sin errores.
- [ ] `gh auth login` completado.
- [ ] Bash es la shell de login.
- [ ] `./scripts/test.sh` y `./scripts/verify.sh` pasan.
- [ ] Ghostty conserva el tema de Omarchy.
- [ ] Configuración local y claves restauradas.
- [ ] Vaults de Obsidian intactos.
- [ ] Módulos opcionales instalados solo si hacen falta.
