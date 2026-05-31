#Requires -Version 5.1
# Instalador de Windows; dejo el hechizo completo aqui para cuando se olvide el README:
# irm https://raw.githubusercontent.com/gibran564/nexdev/main/install.ps1 | iex
# Hace el combo: detecta arquitectura, baja release, instala binario, agrega wrapper y revisa dependencias.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Datos base del instalador; si cambias repo/binario, todo lo de abajo sigue esa pista.

$Repo        = "gibran564/nexdev"
$Binary      = "nexdev.exe"
$InstallDir  = if ($env:NEXDEV_INSTALL_DIR) {
    $env:NEXDEV_INSTALL_DIR
} else {
    Join-Path $HOME '.local\bin'
}

# Paleta Catppuccin Mocha para que PowerShell no se vea tan modo oficina gris.

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

function Invoke-ChocoInstall([string]$Package, [string]$Name) {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        return $false
    }

    Info "Instalando $Name con Chocolatey..."
    try {
        & choco install $Package -y --no-progress
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Invoke-ScoopInstall([string]$Package, [string]$Name) {
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        return $false
    }

    Info "Instalando $Name con scoop..."
    try {
        & scoop install $Package
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Invoke-MiseInstall([string]$Tool, [string]$Name) {
    if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
        return $false
    }

    Info "Instalando $Name con mise..."
    try {
        & mise use -g $Tool
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Install-FzfFromGitHubRelease {
    $tmpDir = [System.IO.Path]::GetTempPath() | Join-Path -ChildPath "fzf_install_$([System.IO.Path]::GetRandomFileName())"
    New-Item -ItemType Directory -Path $tmpDir | Out-Null

    try {
        Info "Instalando fzf desde GitHub Releases..."
        $release = Invoke-RestMethod 'https://api.github.com/repos/junegunn/fzf/releases/latest'
        $asset = $release.assets | Where-Object { $_.name -match 'windows_amd64\.zip$' } | Select-Object -First 1
        if (-not $asset) { return $false }

        $zipPath = Join-Path $tmpDir $asset.name
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing
        Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force

        $fzfExe = Get-ChildItem -Path $tmpDir -Filter 'fzf.exe' -Recurse | Select-Object -First 1
        if (-not $fzfExe) { return $false }

        if (-not (Test-Path $InstallDir)) {
            New-Item -ItemType Directory -Path $InstallDir | Out-Null
        }

        Copy-Item $fzfExe.FullName (Join-Path $InstallDir 'fzf.exe') -Force
        $env:PATH = "$InstallDir;$env:PATH"
        Success "fzf instalado desde GitHub Releases"
        return $true
    } catch {
        return $false
    } finally {
        Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
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
        $fzfVer = & fzf --version 2>$null
        if (-not $fzfVer) { $fzfVer = "desconocida" }
        Success "fzf encontrado ($fzfVer)"
        return
    }

    Warn "fzf no encontrado. nexdev lo necesita para funcionar."
    if (-not (Confirm-Yes "Instalar fzf ahora?")) {
        Warn "Instala fzf manualmente antes de usar nexdev."
        return
    }

    if (Invoke-WingetInstall 'junegunn.fzf' 'fzf') {
        Success "fzf instalado con winget"
        return
    }

    if (Invoke-ScoopInstall 'fzf' 'fzf') {
        Success "fzf instalado con scoop"
        return
    }

    if (Invoke-ChocoInstall 'fzf' 'fzf') {
        Success "fzf instalado con Chocolatey"
        return
    }

    if (Invoke-MiseInstall 'fzf@latest' 'fzf') {
        Success "fzf instalado con mise"
        return
    }

    if (Install-FzfFromGitHubRelease) {
        return
    }

    Warn "No se pudo instalar fzf automáticamente."
    Write-Host "  `e[38;2;108;112;134mOpciones manuales:`e[0m"
    Write-Host "    `e[38;2;148;226;213mwinget install junegunn.fzf`e[0m"
    Write-Host "    `e[38;2;148;226;213mscoop install fzf`e[0m"
    Write-Host "    `e[38;2;148;226;213mchoco install fzf -y`e[0m"
    Write-Host "    `e[38;2;148;226;213mmise use -g fzf@latest`e[0m"
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

# Mensaje inicial: sirve para confirmar que PowerShell si esta ejecutando este script.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:TERM = 'xterm-256color'

Write-Host ""
Write-Host "  `e[38;2;203;166;247m`e[1mnexdev`e[0m  `e[38;2;108;112;134m— instalador para Windows`e[0m"
Write-Host "  `e[38;2;108;112;134m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`e[0m"
Write-Host ""

# Revisamos arquitectura antes de bajar nada; instalar el exe equivocado seria speedrun de error.

$arch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
$archSuffix = switch ($arch) {
    'X64'   { 'x86_64' }
    'Arm64' { 'arm64'  }   # futuro: cuando exista binario ARM64 de Windows, este valor ya queda medio encaminado.
    default { Fail "Arquitectura no soportada: $arch" }
}

# De momento Windows usa x86_64; ARM64 queda apuntado para despues, como tarea en backlog.
$Artifact = "nexdev-windows-x86_64"
$Archive  = "${Artifact}.zip"

Info "Plataforma detectada: Windows/${archSuffix}"

# Preguntamos a GitHub por la release mas nueva para no clavar versiones a mano.

Info "Consultando última versión en GitHub..."

try {
    $release    = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"
    $latestTag  = $release.tag_name
} catch {
    Fail "No se pudo obtener la versión. Verifica que el repo '$Repo' exista y tenga releases."
}

Info "Versión más reciente: `e[38;2;148;226;213m${latestTag}`e[0m"

# Armamos URLs y bajamos el zip; aqui empieza la parte de traer el loot.

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

# Validamos sha256 si GitHub trae el archivo; mejor desconfiar poquito que instalar basura.
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

# Descomprimimos y copiamos el exe a la carpeta final; ya casi aparece el protagonista.

Expand-Archive -Path $tmpArchive -DestinationPath $tmpDir -Force
Remove-Item $tmpArchive

# Creamos la carpeta si falta; PowerShell no adivina destinos, aunque a veces parezca boss final.
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir | Out-Null
}

$extractedBin = Join-Path $tmpDir "nexdev.exe"
Copy-Item $extractedBin (Join-Path $InstallDir $Binary) -Force
Remove-Item $tmpDir -Recurse -Force

Success "Instalado en `e[38;2;148;226;213m${InstallDir}\${Binary}`e[0m"

# Metemos la carpeta al PATH de usuario para poder escribir `nexdev` sin ruta completa.

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

# El wrapper vive en el profile: asi PowerShell puede hacer cd despues de que nexdev elija ruta.

Write-Host ""
Write-Host "  `e[38;2;203;166;247m`e[1mIntegración de shell`e[0m  `e[38;2;108;112;134m(requerida para que cd funcione)`e[0m"
Write-Host ""

$snippet = @'

# Wrapper de nexdev: con args ejecuta comandos; sin args abre selector y cambia carpeta.
function nexdev {
    if ($args.Count -gt 0) {
        & nexdev.exe @args
        return
    }

    $selected = & nexdev.exe
    if ($selected) { Set-Location $selected }
}
'@

# Si no existe el profile, lo creamos; sin archivo no hay donde pegar el wrapper.
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

# Revisamos lo extra: fzf para buscar y Nerd Font para que los iconos no salgan en tofu.

Ensure-Fzf
Ensure-NerdFont

# Final con recordatorio, porque reiniciar terminal es el paso que todos olvidamos.

Write-Host ""
Write-Host "  `e[38;2;166;227;161m`e[1m¡Listo!`e[0m"
Write-Host ""
Write-Host "  Próximos pasos:"
Write-Host "    `e[38;2;203;166;247m1.`e[0m Abre una `e[38;2;148;226;213mnueva terminal`e[0m (para que tome el PATH y el $PROFILE)"
Write-Host "    `e[38;2;203;166;247m2.`e[0m Ejecuta `e[38;2;148;226;213mnexdev`e[0m — el asistente de configuración aparece automáticamente"
Write-Host "    `e[38;2;203;166;247m3.`e[0m O configura manualmente: `e[38;2;148;226;213mnexdev add C:\Users\$env:USERNAME\projects`e[0m"
Write-Host ""
