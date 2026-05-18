#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#  install.sh — nexdev installer for Linux and macOS
#
#  Uso:
#    curl -fsSL https://raw.githubusercontent.com/gibran564/nexdev/main/install.sh | sh
#
#  Qué hace:
#    1. Detecta OS y arquitectura
#    2. Descarga el binario correcto de GitHub Releases
#    3. Lo instala en ~/.local/bin (o /usr/local/bin con sudo)
#    4. Muestra el snippet de integración de shell
#    5. Ofrece instalar fzf y JetBrainsMono Nerd Font
# ══════════════════════════════════════════════════════════════

set -euo pipefail

# ── Config ────────────────────────────────────────────────────

REPO="gibran564/nexdev"
BINARY="nexdev"
INSTALL_DIR="${NEXDEV_INSTALL_DIR:-$HOME/.local/bin}"

# Colores (Catppuccin Mocha)
MAUVE='\033[38;2;203;166;247m'
TEAL='\033[38;2;148;226;213m'
GREEN='\033[38;2;166;227;161m'
RED='\033[38;2;243;139;168m'
PEACH='\033[38;2;250;179;135m'
OVERLAY='\033[38;2;108;112;134m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { printf "  ${TEAL}→${RESET}  %s\n" "$*"; }
success() { printf "  ${GREEN}✓${RESET}  %s\n" "$*"; }
warn()    { printf "  ${PEACH}!${RESET}  %s\n" "$*"; }
error()   { printf "  ${RED}✗${RESET}  %s\n" "$*" >&2; exit 1; }

confirm_yes() {
  local message="$1"
  local answer
  printf "  ${MAUVE}?${RESET}  %s [Y/n]: " "$message"
  read -r answer </dev/tty || answer=""
  case "${answer,,}" in
    n|no) return 1 ;;
    *) return 0 ;;
  esac
}

install_fzf_if_missing() {
  printf "\n"
  if command -v fzf >/dev/null 2>&1; then
    success "fzf encontrado ($(fzf --version 2>/dev/null || printf 'desconocida'))"
    return
  fi

  warn "fzf no encontrado. nexdev lo necesita para funcionar."
  if ! confirm_yes "Instalar fzf ahora?"; then
    warn "Instala fzf manualmente antes de usar nexdev."
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install fzf && success "fzf instalado" && return
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y fzf && success "fzf instalado" && return
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y fzf && success "fzf instalado" && return
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm fzf && success "fzf instalado" && return
  fi

  warn "No se pudo instalar fzf automáticamente."
  printf "  ${OVERLAY}Instalación manual: https://github.com/junegunn/fzf${RESET}\n"
}

nerd_font_installed() {
  if command -v fc-list >/dev/null 2>&1 && fc-list | grep -qi 'Nerd Font'; then
    return 0
  fi
  find "$HOME/.local/share/fonts" "$HOME/Library/Fonts" -iname '*Nerd*Font*' -print -quit 2>/dev/null | grep -q .
}

install_nerd_font_if_missing() {
  printf "\n"
  if nerd_font_installed; then
    success "Nerd Font detectada"
    return
  fi

  warn "No se detectó una Nerd Font. Los iconos pueden verse como cuadros."
  if ! confirm_yes "Instalar JetBrainsMono Nerd Font ahora?"; then
    warn "Configura una Nerd Font en tu terminal para ver los iconos."
    return
  fi

  if [ "$PLATFORM" = "macos" ] && command -v brew >/dev/null 2>&1; then
    brew install --cask font-jetbrains-mono-nerd-font \
      && success "JetBrainsMono Nerd Font instalada" \
      && warn "Selecciona 'JetBrainsMono Nerd Font' en tu terminal." \
      && return
  fi

  if command -v unzip >/dev/null 2>&1; then
    local font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
    local tmp_font_zip
    tmp_font_zip="$(mktemp)"
    if ! mkdir -p "$font_dir"; then
      warn "No se pudo crear el directorio de fuentes: ${font_dir}"
      rm -f "$tmp_font_zip"
      return
    fi

    if ! $DOWNLOAD_TO "$tmp_font_zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"; then
      warn "No se pudo descargar JetBrainsMono Nerd Font."
      rm -f "$tmp_font_zip"
      return
    fi

    if ! unzip -oq "$tmp_font_zip" -d "$font_dir"; then
      warn "No se pudo descomprimir la fuente en ${font_dir}."
      rm -f "$tmp_font_zip"
      return
    fi

    rm -f "$tmp_font_zip"

    if command -v fc-cache >/dev/null 2>&1; then
      if ! fc-cache -f "$font_dir"; then
        warn "La fuente se instaló, pero no se pudo refrescar la caché de fuentes."
      fi
    else
      warn "La fuente se instaló, pero 'fc-cache' no está disponible para refrescar caché."
    fi

    success "JetBrainsMono Nerd Font instalada en ${font_dir}"
    warn "Selecciona 'JetBrainsMono Nerd Font' en tu terminal."
    return
  fi

  warn "No se pudo instalar la fuente automáticamente."
  printf "  ${OVERLAY}Instalación manual: https://www.nerdfonts.com/font-downloads${RESET}\n"
}

# ── Banner ────────────────────────────────────────────────────

printf "\n  ${MAUVE}${BOLD}nexdev${RESET}  ${OVERLAY}— instalador${RESET}\n"
printf "  ${OVERLAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"

# ── Detectar OS ───────────────────────────────────────────────

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux)  PLATFORM="linux"  ;;
  Darwin) PLATFORM="macos"  ;;
  *)      error "Sistema no soportado: $OS. Usa el instalador de Windows (install.ps1)." ;;
esac

case "$ARCH" in
  x86_64 | amd64)  ARCH_SUFFIX="x86_64"  ;;
  aarch64 | arm64) ARCH_SUFFIX="aarch64" ;;
  *)               error "Arquitectura no soportada: $ARCH" ;;
esac

ARTIFACT="nexdev-${PLATFORM}-${ARCH_SUFFIX}"
ARCHIVE="${ARTIFACT}.tar.gz"

info "Plataforma detectada: ${PLATFORM}/${ARCH_SUFFIX}"

# ── Obtener última versión ────────────────────────────────────

info "Consultando última versión en GitHub..."

if command -v curl &>/dev/null; then
  DOWNLOADER="curl -fsSL"
  DOWNLOAD_TO="curl -fsSL -o"
elif command -v wget &>/dev/null; then
  DOWNLOADER="wget -qO-"
  DOWNLOAD_TO="wget -q -O"
else
  error "Se necesita curl o wget para descargar. Instala uno de ellos primero."
fi

LATEST_TAG=$($DOWNLOADER "https://api.github.com/repos/${REPO}/releases/latest" \
  | grep '"tag_name"' \
  | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
  error "No se pudo obtener la versión más reciente. Verifica que el repositorio ${REPO} exista y tenga releases."
fi

info "Versión más reciente: ${TEAL}${LATEST_TAG}${RESET}"

# ── Descargar ─────────────────────────────────────────────────

DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${ARCHIVE}"
TMP_DIR="$(mktemp -d)"
TMP_ARCHIVE="${TMP_DIR}/${ARCHIVE}"

info "Descargando ${ARCHIVE}..."
$DOWNLOAD_TO "$TMP_ARCHIVE" "$DOWNLOAD_URL" \
  || error "Error al descargar desde:\n  ${DOWNLOAD_URL}\n\n  Verifica que la versión ${LATEST_TAG} tenga el archivo ${ARCHIVE}."

# Verificar sha256 si está disponible
SHA256_URL="${DOWNLOAD_URL}.sha256"
TMP_SHA="${TMP_DIR}/${ARCHIVE}.sha256"
if $DOWNLOAD_TO "$TMP_SHA" "$SHA256_URL" 2>/dev/null; then
  info "Verificando integridad (sha256)..."
  if command -v sha256sum &>/dev/null; then
    (cd "$TMP_DIR" && sha256sum -c "$TMP_SHA" --quiet) \
      || error "Verificación sha256 fallida — descarga corrupta."
  elif command -v shasum &>/dev/null; then
    (cd "$TMP_DIR" && shasum -a 256 -c "$TMP_SHA" --quiet) \
      || error "Verificación sha256 fallida — descarga corrupta."
  fi
  success "Integridad verificada"
fi

# ── Extraer e instalar ────────────────────────────────────────

tar -xzf "$TMP_ARCHIVE" -C "$TMP_DIR"
rm -f "$TMP_ARCHIVE"

# Crear directorio de instalación si no existe
mkdir -p "$INSTALL_DIR"

install -m 755 "${TMP_DIR}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
rm -rf "$TMP_DIR"

success "Instalado en ${TEAL}${INSTALL_DIR}/${BINARY}${RESET}"

# ── Verificar PATH ────────────────────────────────────────────

if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
  printf "\n"
  warn "${INSTALL_DIR} no está en tu PATH."
  printf "  ${OVERLAY}Agrega esto a tu ~/.bashrc o ~/.zshrc:${RESET}\n\n"
  printf "    ${TEAL}export PATH=\"\$HOME/.local/bin:\$PATH\"${RESET}\n\n"
fi

# ── Integración de shell ──────────────────────────────────────

printf "\n"
printf "  ${MAUVE}${BOLD}Integración de shell${RESET}  ${OVERLAY}(requerida para que cd funcione)${RESET}\n\n"

SHELL_NAME="$(basename "${SHELL:-bash}")"

case "$SHELL_NAME" in
  zsh)
    printf "  Agrega esto a ${TEAL}~/.zshrc${RESET}:\n\n"
    printf "    ${OVERLAY}# nexdev — project navigator${RESET}\n"
    printf "    ${OVERLAY}nexdev() {${RESET}\n"
    printf "    ${OVERLAY}  if (( \$# > 0 )); then${RESET}\n"
    printf "    ${OVERLAY}    command nexdev \"\$@\"${RESET}\n"
    printf "    ${OVERLAY}    return${RESET}\n"
    printf "    ${OVERLAY}  fi${RESET}\n"
    printf "    ${OVERLAY}${RESET}\n"
    printf "    ${OVERLAY}  local selected${RESET}\n"
    printf "    ${OVERLAY}  selected=\$(command nexdev)${RESET}\n"
    printf "    ${OVERLAY}  [[ -n \"\$selected\" ]] && cd \"\$selected\"${RESET}\n"
    printf "    ${OVERLAY}}${RESET}\n\n"
    # Intentar auto-agregar si el usuario lo permite
    printf "  ¿Agregar automáticamente a ~/.zshrc? [Y/n]: "
    read -r AUTO_INSTALL </dev/tty
    if [[ "${AUTO_INSTALL:-y}" =~ ^[Yy]$ ]]; then
      cat >> "$HOME/.zshrc" << 'SNIPPET'

# nexdev — project navigator
nexdev() {
  if (( $# > 0 )); then
    command nexdev "$@"
    return
  fi

  local selected
  selected=$(command nexdev)
  [[ -n "$selected" ]] && cd "$selected"
}
SNIPPET
      success "Snippet agregado a ~/.zshrc  ${OVERLAY}(ejecuta: source ~/.zshrc)${RESET}"
    fi
    ;;
  fish)
    FISH_FUNC="$HOME/.config/fish/functions/nexdev.fish"
    printf "  Guardando en ${TEAL}${FISH_FUNC}${RESET}...\n"
    mkdir -p "$(dirname "$FISH_FUNC")"
    cat > "$FISH_FUNC" << 'SNIPPET'
function nexdev
  if test (count $argv) -gt 0
    command nexdev $argv
    return
  end

  set selected (command nexdev)
  if test -n "$selected"
    cd $selected
  end
end
SNIPPET
    success "Función fish guardada en ${FISH_FUNC}"
    ;;
  bash | *)
    printf "  Agrega esto a ${TEAL}~/.bashrc${RESET}:\n\n"
    printf "    ${OVERLAY}# nexdev — project navigator${RESET}\n"
    printf "    ${OVERLAY}nexdev() {${RESET}\n"
    printf "    ${OVERLAY}  if [ \"\$#\" -gt 0 ]; then${RESET}\n"
    printf "    ${OVERLAY}    command nexdev \"\$@\"${RESET}\n"
    printf "    ${OVERLAY}    return${RESET}\n"
    printf "    ${OVERLAY}  fi${RESET}\n"
    printf "    ${OVERLAY}${RESET}\n"
    printf "    ${OVERLAY}  local selected${RESET}\n"
    printf "    ${OVERLAY}  selected=\$(command nexdev)${RESET}\n"
    printf "    ${OVERLAY}  [ -n \"\$selected\" ] && cd \"\$selected\"${RESET}\n"
    printf "    ${OVERLAY}}${RESET}\n\n"
    printf "  ¿Agregar automáticamente a ~/.bashrc? [Y/n]: "
    read -r AUTO_INSTALL </dev/tty
    if [[ "${AUTO_INSTALL:-y}" =~ ^[Yy]$ ]]; then
      cat >> "$HOME/.bashrc" << 'SNIPPET'

# nexdev — project navigator
nexdev() {
  if [ "$#" -gt 0 ]; then
    command nexdev "$@"
    return
  fi

  local selected
  selected=$(command nexdev)
  [ -n "$selected" ] && cd "$selected"
}
SNIPPET
      success "Snippet agregado a ~/.bashrc  ${OVERLAY}(ejecuta: source ~/.bashrc)${RESET}"
    fi
    ;;
esac

# ── Dependencias ───────────────────────────────────────────────

install_fzf_if_missing
install_nerd_font_if_missing

# ── Primer uso ────────────────────────────────────────────────

printf "\n"
printf "  ${GREEN}${BOLD}¡Listo!${RESET}\n\n"
printf "  Próximos pasos:\n"
printf "    ${MAUVE}1.${RESET} Recarga tu shell o ejecuta ${TEAL}source ~/.bashrc${RESET} / ${TEAL}source ~/.zshrc${RESET}\n"
printf "    ${MAUVE}2.${RESET} Ejecuta ${TEAL}nexdev${RESET} — el asistente de configuración aparecerá automáticamente\n"
printf "    ${MAUVE}3.${RESET} O configura manualmente: ${TEAL}nexdev add ~/projects${RESET}\n\n"
printf "  ${OVERLAY}Si los iconos no se ven bien, selecciona JetBrainsMono Nerd Font en tu terminal.${RESET}\n\n"
