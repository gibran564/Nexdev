# nexdev

Fast project navigation for developers who keep real work spread across many folders.

`nexdev` scans your configured project roots, detects tech stacks, opens an interactive `fzf` picker with a live preview, changes your shell into the selected project, and optionally opens your editor.

Built by [@gibran564](https://github.com/gibran564).

> Status: early personal tool. Public source, not licensed yet. See [License](#license).

---

## Why nexdev

Most project launchers assume every repo lives in one tidy directory. Real machines do not. `nexdev` is for workstations with side projects, client work, experiments, monorepos, old archives, and language-specific folders.

It gives you one command:

```bash
nexdev
```

Then you search, click or scroll through projects, preview what is inside, press Enter, and land in the right directory.

## Highlights

| Feature | What it gives you |
|---|---|
| Interactive project picker | `fzf` UI with keyboard, mouse click, scroll, search, and preview |
| Smart detection | Tags projects by `.git`, `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, and more |
| Live preview | Shows path, branch, remote, git status, and top-level files |
| Shell integration | Changes the current terminal directory after selection |
| Editor launch | Opens `code`, `nvim`, `vim`, `hx`, `idea`, `zed`, or disables editor launch |
| Bilingual UX | Spanish and English, selected at the beginning of setup |
| Configurable roots | Add multiple roots and per-root exclusions without editing code |

## Preview

```text
╭─  nexdev  ─────────────────────────────────────────────────────╮
│  buscar                                                        │
├─ proyectos ──────────────────────┬─ preview ───────────────────┤
│ > my-api       · rust · git      │  my-api                     │
│   dashboard    · next · tailwind │  C:\Users\gibran\projects   │
│   cli-lab      · go · git        │                             │
│   design-tool  · react           │  rama    main               │
│                                  │  remoto  github.com/...     │
│                                  │                             │
│                                  │  src/                       │
│                                  │  Cargo.toml                 │
│                                  │  README.md                  │
╰──────────────────────────────────┴─────────────────────────────╯
```

## Requirements

| Tool | Required | Install |
|---|---:|---|
| [fzf](https://github.com/junegunn/fzf) | Yes | The installer can install it for you |
| [Nerd Font](https://www.nerdfonts.com/) | Recommended | The installer can install JetBrainsMono Nerd Font |
| Rust | Only for source installs | <https://rustup.rs> |

For mouse click and scroll, use a terminal with mouse support, such as Windows Terminal, iTerm2, WezTerm, Kitty, Alacritty, or a modern Linux terminal.

## Install

### Windows PowerShell

```powershell
irm https://raw.githubusercontent.com/gibran564/nexdev/main/install.ps1 | iex
```

The installer downloads the latest Windows release, installs `nexdev.exe` into `$HOME\.local\bin`, adds it to your user `PATH`, adds the shell wrapper to `$PROFILE`, and offers to install `fzf` plus JetBrainsMono Nerd Font.

### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/gibran564/nexdev/main/install.sh | sh
```

The installer downloads the latest release for your OS and architecture, installs it into `~/.local/bin`, helps you add the shell wrapper, and offers to install `fzf` plus JetBrainsMono Nerd Font when possible.

### From source

```bash
cargo install --git https://github.com/gibran564/nexdev
```

After installing from source, run:

```bash
nexdev install
```

That prints the exact shell integration snippet for Bash, Zsh, Fish, and PowerShell.

## First Run

Run:

```bash
nexdev
```

On first launch, `nexdev` starts a setup wizard:

```text
  nexdev  initial setup / configuracion inicial
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1/3  Language / Idioma

     1  Espanol
     2  English

  ? Selecciona idioma / Choose language [1]

  nexdev  configuracion inicial
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  2/3  Donde estan tus proyectos?
     Enter acepta la ruta sugerida. Despues, Enter vacio termina la lista.

  ? Ruta 1 - vacio para terminar [C:\Users\gibran]
  ✓  C:\Users\gibran

  3/3  Editor preferido
     Se usara para abrir el proyecto seleccionado.

  >  1. VS Code  [detectado]
     2. Neovim
     3. Vim
     4. Helix
     5. IntelliJ
     6. Zed
     7. Ninguno
```

Config file locations:

| OS | Path |
|---|---|
| Windows | `%APPDATA%\nexdev\config.toml` |
| Linux/macOS | `~/.config/nexdev/config.toml` |

## Usage

```bash
nexdev
```

Open the project picker. Select a project to `cd` into it and open your configured editor.

```bash
nexdev add ~/projects
nexdev add ~/work --exclude archived legacy build
```

Add project roots. Local exclusions skip noisy folders inside that root.

```bash
nexdev editor code
nexdev editor "code --new-window"
nexdev editor nvim
nexdev editor none
```

Set or disable the editor command.

```bash
nexdev language es
nexdev language en
```

Switch the CLI language.

```bash
nexdev paths
nexdev config
nexdev init
nexdev install
```

Inspect roots, show full config, rerun setup, or print shell integration.

## Commands

| Command | Description |
|---|---|
| `nexdev` | Open the project picker. First run starts setup |
| `nexdev add <path>` | Add a project root |
| `nexdev add <path> --exclude dir1 dir2` | Add a root with local exclusions |
| `nexdev remove <path>` | Remove a configured root |
| `nexdev editor <cmd>` | Set the editor command |
| `nexdev editor none` | Disable editor launch |
| `nexdev language es\|en` | Change language |
| `nexdev paths` | List configured roots |
| `nexdev config` | Show full config |
| `nexdev init` | Rerun setup |
| `nexdev install` | Print shell wrapper snippets |
| `nexdev --help` | Show CLI help |

## Manual Config

```toml
language = "es"
editor = "code"

global_excludes = [
  "Desktop",
  "Documents",
  "Downloads",
  "AppData",
  "node_modules",
  "target",
  ".venv",
]

[[roots]]
path = "C:\\Users\\gibran\\projects"
exclude = ["archived"]

[[roots]]
path = "C:\\Users\\gibran\\work"
exclude = ["legacy", "tmp"]
```

## Project Detection

| Marker | Tag |
|---|---|
| `.git/` | `git` |
| GitHub remote | GitHub icon |
| GitLab remote | GitLab icon |
| Azure DevOps remote | Azure icon |
| `package.json` | `node` |
| `package.json` + `next.config.*` | `next` |
| `package.json` + `"react"` | `react` |
| `package.json` + `"vue"` | `vue` |
| `package.json` + `"svelte"` | `svelte` |
| `tailwind.config.*` | `tailwind` |
| `requirements.txt`, `pyproject.toml`, `setup.py`, `Pipfile` | `python` |
| `*.ipynb` | `jupyter` |
| `Cargo.toml` | `rust` |
| `*.sln`, `*.csproj`, `*.fsproj` | `dotnet` |
| `pom.xml`, `build.gradle`, `build.gradle.kts` | `java` |
| `go.mod` | `go` |

## Shell Integration

A child process cannot change the working directory of its parent shell. `nexdev` solves that with a small shell wrapper:

1. The binary prints the selected path to stdout.
2. The wrapper captures that path.
3. The wrapper runs `cd` / `Set-Location` in the current shell.

Run this to print the snippets:

```bash
nexdev install
```

PowerShell example:

```powershell
function nexdev {
    if ($args.Count -gt 0) {
        & nexdev.exe @args
        return
    }

    $selected = & nexdev.exe
    if ($selected) { Set-Location $selected }
}
```

Bash/Zsh example:

```bash
nexdev() {
  if [ "$#" -gt 0 ]; then
    command nexdev "$@"
    return
  fi

  local selected
  selected=$(command nexdev)
  [ -n "$selected" ] && cd "$selected"
}
```

## Release Artifacts

| OS | Architecture | Artifact |
|---|---|---|
| Linux | x86_64 | `nexdev-linux-x86_64.tar.gz` |
| Linux | ARM64 | `nexdev-linux-aarch64.tar.gz` |
| macOS | Apple Silicon | `nexdev-macos-aarch64.tar.gz` |
| macOS | Intel | `nexdev-macos-x86_64.tar.gz` |
| Windows | x86_64 | `nexdev-windows-x86_64.zip` |

## Development

```bash
cargo fmt
cargo check
cargo run -- --help
cargo run -- init
```

Project layout:

```text
nexdev/
+-- install.sh
+-- install.ps1
+-- Cargo.toml
+-- README.md
+-- src/
    +-- main.rs       # command dispatch
    +-- cli.rs        # clap arguments
    +-- config.rs     # config, setup wizard, commands
    +-- detect.rs     # project type detection
    +-- i18n.rs       # Spanish/English strings
    +-- navigator.rs  # scan, fzf UI, selection handling
    +-- preview.rs    # live preview panel
    +-- shell.rs      # shell wrapper snippets
```

## Roadmap

- Polish release automation and binary checksums.
- Add screenshots or terminal recordings.
- Add tests for config parsing and project detection.
- Decide and publish an explicit license.

## License

No license has been published yet.

That means the source is visible for review and learning, but reuse, redistribution, modification, and commercial use are not granted unless the author adds a license or gives explicit permission.

Copyright (c) 2026 Gibran, [@gibran564](https://github.com/gibran564). All rights reserved.
