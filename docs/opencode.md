# OpenCode V2 en este repositorio

OpenCode V2 separa la configuración del **servidor/agente** de la configuración de la **terminal**.
El repositorio versiona solo la primera; la segunda es preferencia local de cada equipo.

## Instalación

OpenCode V2 es el paquete oficial `opencode` de los repositorios de Arch/CachyOS:

```bash
sudo pacman -S --needed opencode
opencode --version     # opencode v2.x
```

No se usa el RPM de Fedora, Terra ni un instalador remoto. El paquete ya deja el
CLI en `PATH`; no hace falta enlazar nada en `~/.local/bin`.

Verificación:

```bash
opencode --version
opencode plugin list
```

## Archivos versionados

`opencode/.config/opencode/` se enlaza a `~/.config/opencode/`:

| Archivo | Función |
|---|---|
| `opencode.jsonc` | Config global V2: modelo, plugins, límites, compactación, permisos |
| `AGENTS.md` | Reglas globales: Ponytail Lite, disciplina de tokens, seguridad |
| `dcp.jsonc` | Configuración de Dynamic Context Pruning (DCP) |
| `opencode.omniroute.example.jsonc` | Plantilla de proveedor OmniRoute, **no** activa |

`~/.config/opencode/service.json` (contraseña del servicio) y `auth.json` **no** se versionan.
Tampoco `dcp-prompts/`.

### Configuración de terminal

Temas, keybinds y preferencias de la TUI viven en `~/.config/opencode/cli.json`. No se versiona
porque depende de la terminal y de la sesión; si querés conservarlo, agregalo como un paquete Stow
aparte después de revisarlo.

## Modelo

`opencode.jsonc` usa:

```jsonc
"model": "opencode/big-pickle"
```

Es un modelo disponible sin configurar proveedores externos. Para usar OmniRoute, cambiá el modelo
a `omniroute/auto` después de completar la sección de OmniRoute.

## Plugins

```jsonc
"plugins": [
  "@tarquinen/opencode-dcp@3.2.0"
]
```

- **DCP** (`@tarquinen/opencode-dcp`) soporta la API de plugins V2. Está fijado a una versión
  exacta y `dcp.jsonc` tiene `autoUpdate: false`.
- **Ponytail** (`opencode-ponytail@4.7.3`) es V1-only: su implementación no corre en V2. Por eso
  **no** se instala como plugin y no hay `~/.config/ponytail/config.json` (sería configuración
  muerta). Su ruleset **Lite** está en `AGENTS.md`, que V2 carga globalmente.
- No hay plugins duplicados. Si agregás uno, revisá que no repita funciones de DCP.

`opencode plugin list` puede mostrar “No plugins found” antes del primer arranque del servicio.
El plugin se descarga cuando OpenCode inicia con la configuración desplegada.

### DCP

`dcp.jsonc` mantiene:

- poda automática conservadora;
- protección de los primeros turnos (`turnProtection.turns: 4`);
- `AGENTS.md` y `.env*` protegidos (no se comprimen ni eliminan);
- `autoUpdate: false` para que una actualización del plugin no cambie el contexto en silencio.

Para actualizar DCP:

1. Revisá las notas de la nueva versión.
2. Cambiá la versión en `opencode.jsonc` y, si hace falta, las claves de `dcp.jsonc`.
3. `opencode plugin list` y probá una sesión.

## Optimización de tokens

La estrategia es explícita y no depende de un plugin incompatible:

- `AGENTS.md` define el modo Ponytail Lite: no abstracciones ni dependencias no pedidas, inspección
  dirigida, reportes cortos, skills solo cuando hacen falta.
- `tool_output.max_lines` / `max_bytes` acotan la salida de las herramientas.
- `compaction.auto` con `keep.tokens` y `buffer` conserva contexto reciente sin crecer sin límite.
- `watcher.ignore` evita indexar `.git`, `node_modules`, `dist`, `build`, `target` y `.cache`.
- Los subagentes se usan solo para trabajo independiente que no se puede resolver en una pasada.

## Permisos

`opencode.jsonc` pide confirmación para:

- `git push *`
- `sudo *`
- `rm -rf *`
- acceso a directorios externos (`external_directory`)

Agregá reglas en el mismo array ordenado (`permissions`) si necesitás excepciones. En V2 la última
regla que coincide gana.

## OmniRoute (opcional)

OmniRoute es un gateway local compatible con OpenAI. La plantilla
`opencode.omniroute.example.jsonc` no está activa.

Para activarlo:

1. Levantá el gateway en `http://127.0.0.1:20128/v1`.
2. Copiá el bloque `providers.omniroute` de la plantilla a `opencode.jsonc`.
3. Exportá la clave **solo** en el entorno:

   ```bash
   export OMNIROUTE_API_KEY='...'
   ```

   o guardala en un archivo fuera del repo y usá `{file:~/.secrets/omniroute}`.
4. Cambiá `model` a `omniroute/auto` (o `omniroute/auto/coding`).
5. `opencode models` para confirmar que aparece el proveedor.

Nunca escribas la clave en `opencode.jsonc` ni en la plantilla.

## Addy skills (opcional)

`scripts/install-addy-skills.sh` instala skills de
<https://github.com/addyosmani/agent-skills> en `~/.config/opencode/skills/`.

- Commit fijado: `301b02b12bff98e4688e6984af6556802322bbde`.
- Por defecto instala un subconjunto curado (spec, planificación, implementación incremental, TDD,
  debugging, code review, simplificación, frontend, Git, seguridad).
- `--all` instala las 25 skills.
- `--skill <id>` agrega una puntual.
- `--list` lista las disponibles en el commit fijado.
- Las skills referencian `../../references`, por eso el script copia `references/` a
  `~/.config/opencode/references/`.
- Mantiene un manifiesto (`~/.config/opencode/skills/.addy-skills`) y solo reemplaza lo que él
  mismo instaló.
- **No** copia el `AGENTS.md` del repo de Addy: ese archivo configura el desarrollo de ese repo,
  no tu entorno.

Las skills se anuncian por ID y descripción y se cargan bajo demanda, así que no inflan el
contexto hasta que se usan.

## Graphify (opcional)

`scripts/install-graphify.sh` instala `graphifyy==0.9.103` con `uv` (o `pipx`).

```bash
./scripts/install-graphify.sh --dry-run
./scripts/install-graphify.sh
./scripts/install-graphify.sh --configure ~/proyecto
```

`--configure` ejecuta `graphify install --platform opencode` **solo** en el directorio indicado.
Graphify escribe instrucciones en el proyecto; el script no toca el `AGENTS.md` global ni lo activa
en todos los proyectos.

## Verificación

```bash
cd ~/dotfiles
./scripts/verify.sh
opencode plugin list
opencode debug config
```

`verify.sh` parsea los JSONC, revisa los enlaces, busca secretos y comprueba que DCP sea visible.
`opencode debug config` muestra las fuentes de configuración que el servicio está usando.

## Problemas frecuentes

| Síntoma | Solución |
|---|---|
| `opencode: command not found` | `sudo pacman -S opencode`; abrí una shell nueva o `source ~/.bashrc`. |
| El plugin no aparece | Iniciá OpenCode una vez (`opencode`), luego `opencode plugin list`. Revisá la red. |
| DCP no poda nada | Verificá `dcp.jsonc` y que el plugin figure en `plugins`; `opencode plugin list`. |
| Error de JSONC | `./scripts/verify.sh`; los comentarios y comas finales son válidos, pero el resto debe ser JSON. |
| Cambié `opencode.jsonc` y no pasa nada | OpenCode recarga solo; si no, `/reload` o `opencode service restart`. |
| OmniRoute no aparece | El gateway debe estar en `127.0.0.1:20128`, con el bloque `providers` activo y la clave exportada. |
| Se filtró una clave | Rotala, sacala del archivo y recordá que borrarla del commit no la borra del historial. |
