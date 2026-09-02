#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# p3 - install.sh
# Installs everything needed for K3d + Argo CD: a container runtime
# (Docker if present, Podman as fallback), k3d, and kubectl.
# Idempotent: safe to re-run.
# ---------------------------------------------------------------------------

log() { echo -e "\033[1;34m[install]\033[0m $*"; }

# ---------------------------------------------------------------------------
# 1. Container runtime detection: Docker first, Podman fallback
# ---------------------------------------------------------------------------
if command -v docker &>/dev/null; then
    log "Docker found: $(docker --version)"
    RUNTIME="docker"
elif command -v podman &>/dev/null; then
    log "Podman found: $(podman --version)"
    RUNTIME="podman"

    # k3d talks to the Docker API. On podman, expose that API via the
    # rootless podman socket and point DOCKER_HOST at it.
    log "Configuring podman socket for k3d (Docker-API compatibility)..."
    systemctl --user enable --now podman.socket 2>/dev/null || \
        log "WARNING: could not enable podman.socket via systemctl --user (may already be running, or need manual start)"

    PODMAN_SOCK="/run/user/$(id -u)/podman/podman.sock"
    if [ -S "$PODMAN_SOCK" ]; then
        export DOCKER_HOST="unix://${PODMAN_SOCK}"
        log "DOCKER_HOST set to ${DOCKER_HOST}"
    else
        log "WARNING: podman socket not found at ${PODMAN_SOCK}. k3d may fail until this is fixed."
    fi

    # Persist DOCKER_HOST for subsequent shells/scripts in this session
    echo "export DOCKER_HOST=unix://${PODMAN_SOCK}" >> "${HOME}/.bashrc" 2>/dev/null || true
else
    log "ERROR: neither docker nor podman found. Install one of them first."
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. k3d
# ---------------------------------------------------------------------------
if ! command -v k3d &>/dev/null; then
    log "Installing k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
    log "k3d already installed: $(k3d version | head -n1)"
fi

# ---------------------------------------------------------------------------
# 3. kubectl
# ---------------------------------------------------------------------------
if ! command -v kubectl &>/dev/null; then
    log "Installing kubectl..."
    KUBECTL_VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
else
    log "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

log "Runtime in use: ${RUNTIME}"
log "Done. Next: run scripts/setup.sh to create the cluster and deploy Argo CD."
