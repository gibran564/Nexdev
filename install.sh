#!/usr/bin/env bash
# Instalador para Linux/macOS; dejo el comando aqui para no andar cazandolo en el README:
# curl -fsSL https://raw.githubusercontent.com/gibran564/nexdev/main/install.sh | bash
 
set -eu
 
REPO="gibran564/nexdev"
BINARY="nexdev"
INSTALL_DIR="${NEXDEV_INSTALL_DIR:-$HOME/.local/bin}"
 
# Paleta Catppuccin Mocha; puro drip visual para que la terminal no parezca NPC.
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
 
# Pregunta directo a la terminal; si no hay modo interactivo, mejor no fingir que escuchamos.
confirm_yes() {
  local message="$1"
  local answer=""
 
  if [ -c /dev/tty ]; then
    printf "  ${MAUVE}?${RESET}  %s [Y/n]: " "$message"
    read -r answer < /dev/tty || answer=""
  else
    warn "No se puede leer entrada interactiva. Saltando: $message"
    return 1
  fi
 
  answer="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')"
  case "$answer" in
    n|no) return 1 ;;
    *)    return 0 ;;
  esac
}
 
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

run_with_sudo_if_needed() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command_exists sudo; then
    sudo "$@"
  else
    warn "Se necesita sudo para ejecutar: $*"
    return 1
  fi
}

install_fzf_from_git() {
  if ! command_exists git; then
    return 1
  fi

  local fzf_dir="${FZF_INSTALL_DIR:-$HOME/.fzf}"
  if [ -d "$fzf_dir/.git" ]; then
    info "Actualizando fzf desde ${fzf_dir}..."
    git -C "$fzf_dir" pull --ff-only --depth 1 >/dev/null 2>&1 || true
  else
    info "Instalando fzf desde GitHub en ${fzf_dir}..."
    rm -rf "$fzf_dir"
    git clone --depth 1 https://github.com/junegunn/fzf.git "$fzf_dir" || return 1
  fi

  "$fzf_dir/install" --bin --key-bindings --completion --no-update-rc \
    && success "fzf instalado desde GitHub" \
    && warn "Para atajos/completado de fzf, ejecuta: ${fzf_dir}/install" \
    && return 0

  return 1
}

install_fzf_if_missing() {
  printf "\n"
  if command_exists fzf; then
    success "fzf encontrado ($(fzf --version 2>/dev/null || printf 'desconocida'))"
    return
  fi

  warn "fzf no encontrado. nexdev lo necesita para funcionar."

  if [ -c /dev/tty ] && ! confirm_yes "Instalar fzf ahora?"; then
    warn "Instala fzf manualmente antes de usar nexdev."
    return
  elif ! [ -c /dev/tty ]; then
    info "Instalación no interactiva: intentando métodos disponibles automáticamente."
  fi

  if command_exists brew; then
    info "Instalando fzf con Homebrew..."
    brew install fzf && success "fzf instalado con Homebrew" && return
  fi

  if command_exists mise; then
    info "Instalando fzf con mise..."
    mise use -g fzf@latest && success "fzf instalado con mise" && return
  fi

  if command_exists apt-get; then
    info "Instalando fzf con apt..."
    run_with_sudo_if_needed apt-get update \
      && run_with_sudo_if_needed apt-get install -y fzf \
      && success "fzf instalado con apt" \
      && return
  fi

  if command_exists dnf; then
    info "Instalando fzf con dnf..."
    run_with_sudo_if_needed dnf install -y fzf && success "fzf instalado con dnf" && return
  fi

  if command_exists pacman; then
    info "Instalando fzf con pacman..."
    run_with_sudo_if_needed pacman -S --needed --noconfirm fzf && success "fzf instalado con pacman" && return
  fi

  if command_exists zypper; then
    info "Instalando fzf con zypper..."
    run_with_sudo_if_needed zypper --non-interactive install fzf && success "fzf instalado con zypper" && return
  fi

  if command_exists apk; then
    info "Instalando fzf con apk..."
    run_with_sudo_if_needed apk add --no-cache fzf && success "fzf instalado con apk" && return
  fi

  if command_exists eopkg; then
    info "Instalando fzf con eopkg..."
    run_with_sudo_if_needed eopkg install -y fzf && success "fzf instalado con eopkg" && return
  fi

  if command_exists nix-env; then
    info "Instalando fzf con nix-env..."
    nix-env -iA nixpkgs.fzf && success "fzf instalado con nix-env" && return
  fi

  if install_fzf_from_git; then
    return
  fi

  warn "No se pudo instalar fzf automáticamente."
  printf "  ${OVERLAY}Opciones manuales:${RESET}\n"
  printf "    ${TEAL}brew install fzf${RESET}\n"
  printf "    ${TEAL}mise use -g fzf@latest${RESET}\n"
  printf "    ${TEAL}git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install${RESET}\n"
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
 
  if ! [ -c /dev/tty ]; then
    warn "Instala una Nerd Font manualmente: https://www.nerdfonts.com/font-downloads"
    return
  fi
 
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
    mkdir -p "$font_dir" || { warn "No se pudo crear: ${font_dir}"; rm -f "$tmp_font_zip"; return; }
 
    if ! $DOWNLOAD_TO "$tmp_font_zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"; then
      warn "No se pudo descargar JetBrainsMono Nerd Font."
      rm -f "$tmp_font_zip"
      return
    fi
 
    unzip -oq "$tmp_font_zip" -d "$font_dir" || { warn "No se pudo descomprimir."; rm -f "$tmp_font_zip"; return; }
    rm -f "$tmp_font_zip"
    command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$font_dir" || true
    success "JetBrainsMono Nerd Font instalada en ${font_dir}"
    warn "Selecciona 'JetBrainsMono Nerd Font' en tu terminal."
    return
  fi
 
  warn "No se pudo instalar la fuente automáticamente."
  printf "  ${OVERLAY}Instalación manual: https://www.nerdfonts.com/font-downloads${RESET}\n"
}
 
# Primero saludamos bonito; ayuda a saber que el script si arranco y no se quedo congelado.
 
printf "\n  ${MAUVE}${BOLD}nexdev${RESET}  ${OVERLAY}— instalador${RESET}\n"
printf "  ${OVERLAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n\n"
 
# Revisamos sistema y arquitectura antes de descargar, porque un binario equivocado hace kaboom silencioso.
 
OS="$(uname -s)"
ARCH="$(uname -m)"
 
case "$OS" in
  Linux)  PLATFORM="linux"  ;;
  Darwin) PLATFORM="macos"  ;;
  *)      error "Sistema no soportado: $OS. Usa el instalador de Windows (install.ps1)." ;;
esac
 
case "$ARCH" in
  x86_64|amd64)   ARCH_SUFFIX="x86_64"  ;;
  aarch64|arm64)  ARCH_SUFFIX="aarch64" ;;
  *)              error "Arquitectura no soportada: $ARCH" ;;
esac
 
ARCHIVE="nexdev-${PLATFORM}-${ARCH_SUFFIX}.tar.gz"
info "Plataforma detectada: ${PLATFORM}/${ARCH_SUFFIX}"
 
# Curl o wget, el que exista; con uno basta para traer cosas de GitHub.
 
if command -v curl >/dev/null 2>&1; then
  DOWNLOADER="curl -fsSL"
  DOWNLOAD_TO="curl -fsSL -o"
elif command -v wget >/dev/null 2>&1; then
  DOWNLOADER="wget -qO-"
  DOWNLOAD_TO="wget -q -O"
else
  error "Se necesita curl o wget. Instala uno primero."
fi
 
# Pedimos la release mas nueva a GitHub; asi no hardcodeamos versiones como tarea vieja.
 
info "Consultando última versión en GitHub..."
 
LATEST_TAG=$($DOWNLOADER "https://api.github.com/repos/${REPO}/releases/latest" \
  | grep '"tag_name"' \
  | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')
 
[ -z "$LATEST_TAG" ] && error "No se pudo obtener la versión más reciente del repo ${REPO}."
 
info "Versión más reciente: ${TEAL}${LATEST_TAG}${RESET}"
 
# Bajamos el artefacto que corresponde a esta maquina, nada de mezclar Linux con macOS.
 
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${ARCHIVE}"
TMP_DIR="$(mktemp -d)"
TMP_ARCHIVE="${TMP_DIR}/${ARCHIVE}"
 
info "Descargando ${ARCHIVE}..."
$DOWNLOAD_TO "$TMP_ARCHIVE" "$DOWNLOAD_URL" \
  || error "Error al descargar desde:\n  ${DOWNLOAD_URL}"
 
# Checamos sha256 si viene disponible; no queremos instalar un zip sospechoso modo villano.
SHA256_URL="${DOWNLOAD_URL}.sha256"
TMP_SHA="${TMP_DIR}/${ARCHIVE}.sha256"
if $DOWNLOAD_TO "$TMP_SHA" "$SHA256_URL" 2>/dev/null; then
  info "Verificando integridad (sha256)..."
  if command -v sha256sum >/dev/null 2>&1; then
    (cd "$TMP_DIR" && sha256sum -c "$TMP_SHA" --quiet) || error "sha256 inválido — descarga corrupta."
  elif command -v shasum >/dev/null 2>&1; then
    (cd "$TMP_DIR" && shasum -a 256 -c "$TMP_SHA" --quiet) || error "sha256 inválido — descarga corrupta."
  fi
  success "Integridad verificada"
fi
 
# Descomprimimos y copiamos el binario al directorio elegido; aqui ya se vuelve usable.
 
tar -xzf "$TMP_ARCHIVE" -C "$TMP_DIR"
rm -f "$TMP_ARCHIVE"
mkdir -p "$INSTALL_DIR"
install -m 755 "${TMP_DIR}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
rm -rf "$TMP_DIR"
 
success "Instalado en ${TEAL}${INSTALL_DIR}/${BINARY}${RESET}"
 
# Si la carpeta no esta en PATH, nexdev existe pero la shell se hace la que no lo conoce.
 
if ! printf '%s' "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
  printf "\n"
  warn "${INSTALL_DIR} no está en tu PATH."
  printf "  ${OVERLAY}Agrega esto a tu ~/.bashrc o ~/.zshrc:${RESET}\n\n"
  printf "    ${TEAL}export PATH=\"\$HOME/.local/bin:\$PATH\"${RESET}\n\n"
fi
 
# Este wrapper es la clave: un proceso hijo no puede hacer `cd` por su papa, asi que la shell ayuda.
 
printf "\n"
printf "  ${MAUVE}${BOLD}Integración de shell${RESET}  ${OVERLAY}(requerida para que cd funcione)${RESET}\n\n"
 
SHELL_NAME="$(basename "${SHELL:-bash}")"
 
case "$SHELL_NAME" in
  zsh)
    printf "  Agrega esto a ${TEAL}~/.zshrc${RESET}:\n\n"
    cat <<'SHOW'
    # Wrapper de nexdev: con argumentos manda comandos; sin argumentos abre fzf y luego hace cd.
    nexdev() {
      if (( $# > 0 )); then
        command nexdev "$@"
        return
      fi
      local selected
      selected=$(command nexdev)
      [[ -n "$selected" ]] && cd "$selected"
    }
SHOW
    printf "\n"
    if confirm_yes "Agregar automáticamente a ~/.zshrc?"; then
      cat >> "$HOME/.zshrc" <<'SNIPPET'
 
# Wrapper de nexdev: con argumentos manda comandos; sin argumentos abre fzf y luego hace cd.
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
    cat > "$FISH_FUNC" <<'SNIPPET'
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
 
  bash|*)
    printf "  Agrega esto a ${TEAL}~/.bashrc${RESET}:\n\n"
    cat <<'SHOW'
    # Wrapper de nexdev: con argumentos manda comandos; sin argumentos abre fzf y luego hace cd.
    nexdev() {
      if [ "$#" -gt 0 ]; then
        command nexdev "$@"
        return
      fi
      local selected
      selected=$(command nexdev)
      [ -n "$selected" ] && cd "$selected"
    }
SHOW
    printf "\n"
    if confirm_yes "Agregar automáticamente a ~/.bashrc?"; then
      cat >> "$HOME/.bashrc" <<'SNIPPET'
 
# Wrapper de nexdev: con argumentos manda comandos; sin argumentos abre fzf y luego hace cd.
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
 
# Ultima pasada por dependencias; fzf es obligatorio y la Nerd Font evita cuadritos feos.
 
install_fzf_if_missing
install_nerd_font_if_missing
 
# Cierre con pasos humanos, porque instalar y quedarse mirando la terminal no cuenta como setup.
 
printf "\n"
printf "  ${GREEN}${BOLD}¡Listo!${RESET}\n\n"
printf "  Próximos pasos:\n"
printf "    ${MAUVE}1.${RESET} Recarga tu shell:  ${TEAL}source ~/.zshrc${RESET}  o  ${TEAL}source ~/.bashrc${RESET}\n"
printf "    ${MAUVE}2.${RESET} Ejecuta ${TEAL}nexdev${RESET} — el asistente de configuración aparecerá automáticamente\n"
printf "    ${MAUVE}3.${RESET} O configura manualmente: ${TEAL}nexdev add ~/projects${RESET}\n\n"
printf "  ${OVERLAY}Si los iconos no se ven bien, selecciona JetBrainsMono Nerd Font en tu terminal.${RESET}\n\n"
 
