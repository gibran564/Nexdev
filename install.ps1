#Requires -Version 5.1
# ══════════════════════════════════════════════════════════════
#  install.ps1 — nexdev installer para Windows
#
#  Uso (PowerShell como usuario normal, NO requiere admin):
#    irm https://raw.githubusercontent.com/gibran564/nexdev/main/install.ps1 | iex
#
#  Qué hace:
#    1. Detecta arquitectura (x86_64 / ARM64)
#    2. Descarga el binario correcto de GitHub Releases
#    3. Lo instala en $HOME\.local\bin  (en tu PATH de usuario)
#    4. Agrega el wrapper de función a tu $PROFILE
#    5. Ofrece instalar fzf y JetBrainsMono Nerd Font
# ══════════════════════════════════════════════════════════════

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Config ────────────────────────────────────────────────────

$Repo        = "gibran564/nexdev"
$Binary      = "nexdev.exe"
$InstallDir  = if ($env:NEXDEV_INSTALL_DIR) {
    $env:NEXDEV_INSTALL_DIR
} else {
    Join-Path $HOME '.local\bin'
}

# ── Colores Catppuccin Mocha ──────────────────────────────────

function Write-Color([string]$Text, [int[]]$RGB, [switch]$Bold, [switch]$NoNewline) {
    $code = "`e[38;2;$($RGB[0]);$($RGB[1]);$($RGB[2])m"
    $b    = if ($Bold) { "`e[1m" } else { "" }
    $end  = if ($NoNewline) { "" } else { "`n" }
    Write-Host "${b}${code}${Text}`e[0m" -NoNewline:($NoNewline -or $true)
    if (-not $NoNewline) { Write-Host "" }
}

function Info    { Write-Host "  `e[38;2;148;226;213m→`e[0m  $args" }
function Success { Write-Host "  `e[38;2;166;227;161m✓`e[0m  $args" }
function Warn    { Write-Host "  `e[38;2;250;179;135m!`e[0m  $args" }
function Fail    { Write-Host "  `e[38;2;243;139;168m✗`e[0m  $args" -ForegroundColor Red; exit 1 }

function Confirm-Yes([string]$Message) {
    $answer = Read-Host "  `e[38;2;203;166;247m?`e[0m  $Message [Y/n]"
    return ($answer.Trim().ToLower() -notin @('n', 'no'))
}

function Invoke-WingetInstall([string]$Id, [string]$Name) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        return $false
    }

    Info "Instalando $Name con winget..."
    try {
        & winget install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Test-NerdFontInstalled {
    $fontDirs = @(
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'),
        (Join-Path $env:WINDIR 'Fonts')
    )

    foreach ($dir in $fontDirs) {
        if ((Test-Path $dir) -and (Get-ChildItem $dir -Filter '*Nerd*Font*' -ErrorAction SilentlyContinue | Select-Object -First 1)) {
            return $true
        }
    }

    return $false
}

function Ensure-Fzf {
    Write-Host ""
    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        $fzfVer = (fzf --version 2>$null) ?? "desconocida"
        Success "fzf encontrado ($fzfVer)"
        return
    }

    Warn "fzf no encontrado. nexdev lo necesita para funcionar."
    if (Confirm-Yes "Instalar fzf ahora?") {
        if (Invoke-WingetInstall 'junegunn.fzf' 'fzf') {
            Success "fzf instalado"
            return
        }
        if (Get-Command scoop -ErrorAction SilentlyContinue) {
            Info "Instalando fzf con scoop..."
            & scoop install fzf
            if ($LASTEXITCODE -eq 0) {
                Success "fzf instalado"
                return
            }
        }
        Warn "No se pudo instalar fzf automáticamente."
    }

    Write-Host "  `e[38;2;108;112;134mInstalación manual:`e[0m"
    Write-Host "    `e[38;2;148;226;213mwinget install junegunn.fzf`e[0m"
    Write-Host "    `e[38;2;148;226;213mscoop install fzf`e[0m"
}

function Ensure-NerdFont {
    Write-Host ""
    if (Test-NerdFontInstalled) {
        Success "Nerd Font detectada"
        return
    }

    Warn "No se detectó una Nerd Font. Los iconos pueden verse como cuadros."
    if (Confirm-Yes "Instalar JetBrainsMono Nerd Font ahora?") {
        if (Invoke-WingetInstall 'DEVCOM.JetBrainsMonoNerdFont' 'JetBrainsMono Nerd Font') {
            Success "JetBrainsMono Nerd Font instalada"
            Warn "Selecciona 'JetBrainsMono Nerd Font' en la configuración de tu terminal."
            return
        }
        Warn "No se pudo instalar la fuente automáticamente con winget."
    }

    Write-Host "  `e[38;2;108;112;134mInstalación manual:`e[0m"
    Write-Host "    `e[38;2;148;226;213mwinget install DEVCOM.JetBrainsMonoNerdFont`e[0m"
    Write-Host "    `e[38;2;148;226;213mhttps://www.nerdfonts.com/font-downloads`e[0m"
}

# ── Banner ────────────────────────────────────────────────────

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:TERM = 'xterm-256color'

Write-Host ""
Write-Host "  `e[38;2;203;166;247m`e[1mnexdev`e[0m  `e[38;2;108;112;134m— instalador para Windows`e[0m"
Write-Host "  `e[38;2;108;112;134m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`e[0m"
Write-Host ""

# ── Detectar arquitectura ─────────────────────────────────────

$arch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
$archSuffix = switch ($arch) {
    'X64'   { 'x86_64' }
    'Arm64' { 'arm64'  }   # futuro: cuando haya binario ARM64 Windows
    default { Fail "Arquitectura no soportada: $arch" }
}

# Por ahora solo hay x86_64 para Windows
$Artifact = "nexdev-windows-x86_64"
$Archive  = "${Artifact}.zip"

Info "Plataforma detectada: Windows/${archSuffix}"

# ── Obtener última versión ────────────────────────────────────

Info "Consultando última versión en GitHub..."

try {
    $release    = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"
    $latestTag  = $release.tag_name
} catch {
    Fail "No se pudo obtener la versión. Verifica que el repo '$Repo' exista y tenga releases."
}

Info "Versión más reciente: `e[38;2;148;226;213m${latestTag}`e[0m"

# ── Descargar ─────────────────────────────────────────────────

$baseUrl    = "https://github.com/$Repo/releases/download/$latestTag"
$archiveUrl = "$baseUrl/$Archive"
$sha256Url  = "$archiveUrl.sha256"
$tmpDir     = [System.IO.Path]::GetTempPath() | Join-Path -ChildPath "nexdev_install_$([System.IO.Path]::GetRandomFileName())"
New-Item -ItemType Directory -Path $tmpDir | Out-Null
$tmpArchive = Join-Path $tmpDir $Archive

Info "Descargando $Archive..."
try {
    Invoke-WebRequest -Uri $archiveUrl -OutFile $tmpArchive -UseBasicParsing
} catch {
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    Fail "Error al descargar:`n  $archiveUrl`n  Verifica que la versión $latestTag tenga ese archivo."
}

# Verificar sha256
try {
    $expectedSha = (Invoke-WebRequest -Uri $sha256Url -UseBasicParsing).Content.Trim() -split '\s+' | Select-Object -First 1
    $actualSha   = (Get-FileHash $tmpArchive -Algorithm SHA256).Hash.ToLower()
    if ($expectedSha -ne $actualSha) {
        Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
        Fail "Verificación sha256 fallida — descarga corrupta. Intenta de nuevo."
    }
    Success "Integridad verificada (sha256)"
} catch {
    Warn "No se pudo verificar sha256 — continuando de todas formas."
}

# ── Extraer e instalar ────────────────────────────────────────

Expand-Archive -Path $tmpArchive -DestinationPath $tmpDir -Force
Remove-Item $tmpArchive

# Crear directorio de instalación
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir | Out-Null
}

$extractedBin = Join-Path $tmpDir "nexdev.exe"
Copy-Item $extractedBin (Join-Path $InstallDir $Binary) -Force
Remove-Item $tmpDir -Recurse -Force

Success "Instalado en `e[38;2;148;226;213m${InstallDir}\${Binary}`e[0m"

# ── Agregar al PATH de usuario ────────────────────────────────

$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable(
        "PATH",
        "$InstallDir;$userPath",
        "User"
    )
    $env:PATH = "$InstallDir;$env:PATH"
    Success "Agregado al PATH de usuario"
} else {
    Info "$InstallDir ya está en tu PATH"
}

# ── Integración de shell (función wrapper en $PROFILE) ────────

Write-Host ""
Write-Host "  `e[38;2;203;166;247m`e[1mIntegración de shell`e[0m  `e[38;2;108;112;134m(requerida para que cd funcione)`e[0m"
Write-Host ""

$snippet = @'

# nexdev — project navigator
function nexdev {
    if ($args.Count -gt 0) {
        & nexdev.exe @args
        return
    }

    $selected = & nexdev.exe
    if ($selected) { Set-Location $selected }
}
'@

# Crear $PROFILE si no existe
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue

if ($profileContent -notlike "*function nexdev*") {
    Add-Content $PROFILE $snippet
    Success "Wrapper agregado a `e[38;2;148;226;213m$PROFILE`e[0m"
} else {
    Info "El wrapper ya existe en `$PROFILE — no se modificó."
}

# ── Dependencias ───────────────────────────────────────────────

Ensure-Fzf
Ensure-NerdFont

# ── Listo ─────────────────────────────────────────────────────

Write-Host ""
Write-Host "  `e[38;2;166;227;161m`e[1m¡Listo!`e[0m"
Write-Host ""
Write-Host "  Próximos pasos:"
Write-Host "    `e[38;2;203;166;247m1.`e[0m Abre una `e[38;2;148;226;213mnueva terminal`e[0m (para que tome el PATH y el $PROFILE)"
Write-Host "    `e[38;2;203;166;247m2.`e[0m Ejecuta `e[38;2;148;226;213mnexdev`e[0m — el asistente de configuración aparece automáticamente"
Write-Host "    `e[38;2;203;166;247m3.`e[0m O configura manualmente: `e[38;2;148;226;213mnexdev add C:\Users\$env:USERNAME\projects`e[0m"
Write-Host ""
