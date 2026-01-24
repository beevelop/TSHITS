#!/usr/bin/env bash
# BeeCompose CLI Installer
# Installs the 'bc' command system-wide
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/beevelop/beecompose/main/scripts/install.sh | bash
#
# Options (via environment variables):
#   BC_INSTALL_DIR     Installation directory (default: /usr/local/bin)
#   BC_VERSION         Git ref to install from (default: main)

set -euo pipefail

# Configuration
readonly REPO_URL="https://raw.githubusercontent.com/beevelop/beecompose"
readonly INSTALL_DIR="${BC_INSTALL_DIR:-/usr/local/bin}"
readonly VERSION="${BC_VERSION:-main}"
readonly BC_BINARY="bc"
readonly BC_SCRIPT_URL="${REPO_URL}/${VERSION}/scripts/bc"

# Colors for output
if [[ -t 1 ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[0;33m'
  readonly CYAN='\033[0;36m'
  readonly BOLD='\033[1m'
  readonly NC='\033[0m'
else
  readonly RED='' GREEN='' YELLOW='' CYAN='' BOLD='' NC=''
fi

log() {
  echo -e "${CYAN}[bc-install]${NC} $*"
}

success() {
  echo -e "${GREEN}[bc-install]${NC} $*"
}

warn() {
  echo -e "${YELLOW}[bc-install]${NC} $*" >&2
}

error() {
  echo -e "${RED}[bc-install]${NC} $*" >&2
}

# Check for required commands
check_requirements() {
  local missing=()
  
  if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    missing+=("curl or wget")
  fi
  
  if ! command -v docker &> /dev/null; then
    warn "Docker not found - required for using bc"
  fi
  
  if [[ ${#missing[@]} -gt 0 ]]; then
    error "Missing required tools: ${missing[*]}"
    exit 1
  fi
}

# Download file using curl or wget
download() {
  local url="$1"
  local dest="$2"
  
  if command -v curl &> /dev/null; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget &> /dev/null; then
    wget -qO "$dest" "$url"
  else
    error "Neither curl nor wget found"
    exit 1
  fi
}

# Check if running with sufficient permissions
check_permissions() {
  if [[ ! -d "$INSTALL_DIR" ]]; then
    if ! mkdir -p "$INSTALL_DIR" 2>/dev/null; then
      error "Cannot create $INSTALL_DIR - try running with sudo"
      exit 1
    fi
  fi
  
  if [[ ! -w "$INSTALL_DIR" ]]; then
    error "Cannot write to $INSTALL_DIR - try running with sudo"
    echo ""
    echo "Run with:"
    echo "  curl -fsSL ${BC_SCRIPT_URL/bc/install.sh} | sudo bash"
    exit 1
  fi
}

# Install the bc binary
install_bc() {
  local tmp_file
  tmp_file=$(mktemp)
  trap "rm -f $tmp_file" EXIT
  
  log "Downloading bc from ${REPO_URL}/${VERSION}..."
  
  if ! download "$BC_SCRIPT_URL" "$tmp_file"; then
    error "Failed to download bc script"
    error "URL: $BC_SCRIPT_URL"
    exit 1
  fi
  
  # Verify it's a valid shell script
  if ! head -1 "$tmp_file" | grep -q '^#!/'; then
    error "Downloaded file is not a valid script"
    error "This may indicate a network issue or the version doesn't exist"
    exit 1
  fi
  
  log "Installing to ${INSTALL_DIR}/${BC_BINARY}..."
  
  # Move to install directory
  mv "$tmp_file" "${INSTALL_DIR}/${BC_BINARY}"
  chmod +x "${INSTALL_DIR}/${BC_BINARY}"
  
  # Reset trap since we moved the file
  trap - EXIT
}

# Verify installation
verify_installation() {
  if ! command -v bc &> /dev/null; then
    warn "bc installed but not in PATH"
    warn "Add ${INSTALL_DIR} to your PATH:"
    echo ""
    echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
    echo ""
    warn "Or run directly: ${INSTALL_DIR}/bc"
    return 1
  fi
  
  # Check if our bc is the one in PATH (not GNU bc)
  local installed_bc
  installed_bc=$(which bc)
  
  if [[ "$installed_bc" != "${INSTALL_DIR}/${BC_BINARY}" ]]; then
    warn "Note: 'bc' command may refer to GNU bc calculator"
    warn "Installed BeeCompose bc at: ${INSTALL_DIR}/${BC_BINARY}"
    warn ""
    warn "If GNU bc is installed, you can either:"
    warn "  1. Use full path: ${INSTALL_DIR}/bc"
    warn "  2. Create an alias: alias bc='${INSTALL_DIR}/bc'"
    warn "  3. Rename GNU bc and prioritize BeeCompose bc in PATH"
    return 0
  fi
  
  return 0
}

# Print post-install instructions
print_success() {
  echo ""
  success "BeeCompose CLI installed successfully!"
  echo ""
  echo "Usage:"
  echo "  bc <service> up       Start a service"
  echo "  bc <service> down     Stop a service"
  echo "  bc <service> logs -f  Follow logs"
  echo "  bc list               List available services"
  echo "  bc help               Show help"
  echo ""
  echo "Quick start:"
  echo "  # Create environment file"
  echo "  cat > .env.metabase << 'EOF'"
  echo "  COMPOSE_PROJECT_NAME=metabase"
  echo "  SERVICE_DOMAIN=metabase.example.com"
  echo "  DB_PASS=your-password"
  echo "  EOF"
  echo ""
  echo "  # Start the service"
  echo "  bc metabase up"
  echo ""
  echo "Documentation: https://github.com/beevelop/beecompose"
}

# Uninstall function
uninstall() {
  if [[ -f "${INSTALL_DIR}/${BC_BINARY}" ]]; then
    log "Removing ${INSTALL_DIR}/${BC_BINARY}..."
    rm -f "${INSTALL_DIR}/${BC_BINARY}"
    success "BeeCompose CLI uninstalled"
  else
    warn "bc not found at ${INSTALL_DIR}/${BC_BINARY}"
  fi
}

# Main installation flow
main() {
  # Handle uninstall
  if [[ "${1:-}" == "uninstall" ]] || [[ "${1:-}" == "--uninstall" ]]; then
    check_permissions
    uninstall
    exit 0
  fi
  
  echo ""
  echo -e "${BOLD}BeeCompose CLI Installer${NC}"
  echo "========================="
  echo ""
  
  log "Checking requirements..."
  check_requirements
  
  log "Checking permissions..."
  check_permissions
  
  install_bc
  
  verify_installation || true
  
  print_success
}

main "$@"
