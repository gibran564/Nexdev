# nexdev

Navegador de proyectos multiplataforma con fzf — escrito en Rust.

Catppuccin Mocha · Iconos Nerd Fonts · Preview con info de git · Configurable sin tocar código.

---

## Instalación rápida

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/TU_USUARIO/nexdev/main/install.sh | sh
```

El script detecta tu OS y arquitectura, descarga el binario correcto de GitHub Releases,
lo instala en `~/.local/bin`, y agrega el wrapper de shell a tu rc file automáticamente.

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/TU_USUARIO/nexdev/main/install.ps1 | iex
```

Descarga `nexdev.exe`, lo instala en `$HOME\.local\bin` (sin admin), lo agrega al PATH de usuario,
y escribe el wrapper en `$PROFILE`.

### Con Rust instalado

```bash
cargo install nexdev --git https://github.com/TU_USUARIO/nexdev
```

---

## Prerequisitos

| Herramienta | Por qué | Cómo instalar |
|---|---|---|
| [fzf](https://github.com/junegunn/fzf) | El fuzzy finder | `brew install fzf` / `scoop install fzf` / `winget install junegunn.fzf` |
| [Nerd Font](https://www.nerdfonts.com/) | Iconos de tech stack | Configurar en la terminal |

---

## Lo que hace

`nexdev` escanea directorios configurados buscando proyectos (detectados por `Cargo.toml`,
`package.json`, `requirements.txt`, `.git`, etc.), lanza fzf con panel de preview en vivo,
y mediante un wrapper hace `cd` al proyecto seleccionado y abre tu editor.

```
 proyecto >
╭──────────────────────────────────────╮  ╭──────────────────────────────────╮
│  bubble-intelligence  · rust · git   │  │  burros-itd                      │
│ > burros-itd  · next · tailwind      │  │  /home/christian/projects/       │
│  eclipsis  · node · git              │  │  burros-itd                      │
│  rancho-sport  · next · tailwind     │  │                                  │
╰──────────────────────────────────────╯  │  rama  main                      │
                                           │  remoto  github.com/...          │
                                           │   src/  package.json  README.md  │
                                           ╰──────────────────────────────────╯
```

---

## Primer uso

El asistente aparece automáticamente en el primer run:

```
  nexdev — configuracion inicial
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1. Donde estan tus proyectos?
  Ruta 1 [/home/christian]: /home/christian/projects
  ✓  /home/christian/projects

  2. Que editor debe abrir el proyecto?
  >  1. VS Code  [detectado]
     2. Neovim   3. Vim   4. Ninguno

  Guardar y continuar? [Y/n]:
  ✓  Configuracion guardada. Usa nexdev add <path> para agregar mas rutas.
```

Config en `~/.config/nexdev/config.toml` (Linux/macOS) o `%APPDATA%\nexdev\config.toml` (Windows).

---

## Comandos

```
nexdev                     Abrir el fuzzy finder (primer run -> asistente)
nexdev add <ruta>          Agregar raiz de busqueda
nexdev add <ruta>
  --exclude dir1 dir2    Agregar raiz con exclusiones locales
nexdev remove <ruta>       Eliminar una raiz
nexdev editor <cmd>        Cambiar editor ("none" para deshabilitar)
nexdev language es|en      Cambiar idioma
nexdev paths               Listar raices configuradas
nexdev config              Mostrar configuracion completa
nexdev init                Re-ejecutar el asistente
nexdev install             Mostrar integracion de shell
nexdev --help              Ayuda completa
```

### Ejemplos

```bash
nexdev add ~/projects
nexdev add ~/work --exclude archived legacy build
nexdev editor nvim
nexdev editor "code --new-window"
nexdev editor none
nexdev language en
nexdev language es
nexdev paths
nexdev init
```

---

## Configuracion manual (`config.toml`)

```toml
language = "es"
editor = "code"

global_excludes = [
  "Desktop", "Documents", "Downloads", "AppData",
  "node_modules", "target", ".venv",
]

[[roots]]
path = "/home/christian/projects"
exclude = ["archived"]

[[roots]]
path = "/home/christian/work"
exclude = ["client-a", "legacy"]
```

---

## Deteccion de proyectos

| Archivo(s)                              | Tags            | Icono |
|-----------------------------------------|-----------------|-------|
| `.git/`                                 | `git`           |      |
| `package.json` + `next.config.*`        | `next`          |      |
| `package.json` + `"react"`              | `react`         |      |
| `package.json` + `"vue"`               | `vue`           |      |
| `package.json`                          | `node`          |      |
| `requirements.txt` / `pyproject.toml`  | `python`        |      |
| Archivos `.ipynb`                       | `jupyter`       |      |
| `Cargo.toml`                            | `rust`          |      |
| `*.sln` / `*.csproj`                    | `dotnet`        |      |
| `pom.xml` / `build.gradle`              | `java`          |      |
| `go.mod`                                | `go`            |      |
| `tailwind.config.*`                     | `tailwind`      | —    |

---

## Integracion de shell

> Un proceso hijo no puede cambiar el CWD del shell padre. El binario imprime la ruta
> a stdout; el wrapper la lee y ejecuta `cd`. Ejecuta `nexdev install` para ver el fragmento exacto.

**bash** (`~/.bashrc`):
```bash
nexdev() {
  if [ "$#" -gt 0 ]; then
    command nexdev "$@"
    return
  fi

  local selected
  selected=$(command nexdev "$@")
  [ -n "$selected" ] && cd "$selected"
}
```

**zsh** (`~/.zshrc`):
```zsh
nexdev() {
  if (( $# > 0 )); then
    command nexdev "$@"
    return
  fi

  local selected
  selected=$(command nexdev "$@")
  [[ -n "$selected" ]] && cd "$selected"
}
```

**fish** (`~/.config/fish/functions/nexdev.fish`):
```fish
function nexdev
  if test (count $argv) -gt 0
    command nexdev $argv
    return
  end

  set selected (command nexdev $argv)
  if test -n "$selected"
    cd $selected
  end
end
```

**PowerShell** (`$PROFILE`):
```powershell
function nexdev {
    if ($args.Count -gt 0) {
        & nexdev.exe @args
        return
    }

    $selected = & nexdev.exe @args
    if ($selected) { Set-Location $selected }
}
```

---

## Plataformas

| OS | Arquitectura | Binario |
|---|---|---|
| Linux | x86_64 | `nexdev-linux-x86_64.tar.gz` |
| Linux | ARM64 | `nexdev-linux-aarch64.tar.gz` |
| macOS | Apple Silicon | `nexdev-macos-aarch64.tar.gz` |
| macOS | Intel | `nexdev-macos-x86_64.tar.gz` |
| Windows | x86_64 | `nexdev-windows-x86_64.zip` |

---

## Publicar nueva version

```bash
git tag v0.2.0
git push origin v0.2.0
# GitHub Actions compila para todos los targets y publica el Release automaticamente
```

---

## Estructura

```
nexdev/
+-- .github/
|   +-- workflows/
|       +-- ci.yml        <- verifica compilacion en PRs
|       +-- release.yml   <- build multiplataforma + GitHub Release
+-- install.sh            <- instalador Linux/macOS
+-- install.ps1           <- instalador Windows
+-- Cargo.toml / Cargo.lock
+-- README.md
+-- src/
    +-- main.rs           <- dispatch
    +-- cli.rs            <- argumentos (clap derive)
    +-- config.rs         <- Config, asistente, cmd_add/remove/editor
    +-- detect.rs         <- deteccion de tipo por archivos marker
    +-- navigator.rs      <- escaneo, fzf, seleccion
    +-- preview.rs        <- panel preview (mismo binario via __preview)
    +-- shell.rs          <- integracion de shell
```

---

## Licencia

MIT
