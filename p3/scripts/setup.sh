#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# p3 - setup.sh
# Creates the k3d cluster (with the port mapping the app needs), the two
# required namespaces (argocd, dev), and installs Argo CD.
# Idempotent: safe to re-run against an existing cluster.
# ---------------------------------------------------------------------------

log() { echo -e "\033[1;32m[setup]\033[0m $*"; }

CLUSTER_NAME="iot-p3"
APP_PORT=8888   # wil42/playground listens on 8888

# ---------------------------------------------------------------------------
# 1. Create the k3d cluster (skip if it already exists)
# ---------------------------------------------------------------------------
if k3d cluster list | grep -q "^${CLUSTER_NAME}"; then
    log "Cluster '${CLUSTER_NAME}' already exists, skipping creation."
else
    log "Creating k3d cluster '${CLUSTER_NAME}' (mapping host:${APP_PORT} -> loadbalancer:${APP_PORT})..."
    k3d cluster create "${CLUSTER_NAME}" \
        --port "${APP_PORT}:${APP_PORT}@loadbalancer" \
        --wait
fi

kubectl cluster-info
kubectl get nodes -o wide

# ---------------------------------------------------------------------------
# 2. Namespaces
# ---------------------------------------------------------------------------
log "Creating namespaces (argocd, dev)..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev    --dry-run=client -o yaml | kubectl apply -f -

# ---------------------------------------------------------------------------
# 3. Install Argo CD
# ---------------------------------------------------------------------------
log "Installing Argo CD into 'argocd' namespace..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

log "Waiting for Argo CD server to be ready (this can take a couple of minutes)..."
kubectl -n argocd wait --for=condition=available --timeout=300s deployment/argocd-server

# ---------------------------------------------------------------------------
# 4. Retrieve the initial admin password
# ---------------------------------------------------------------------------
log "Argo CD initial admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d
echo
log "Username: admin"

log "To reach the Argo CD UI, in another terminal run:"
echo "    kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "Then browse to https://localhost:8080"

# ---------------------------------------------------------------------------
# 5. Apply the Argo CD Application resource
# ---------------------------------------------------------------------------
log "Applying the Argo CD Application manifest..."
kubectl apply -f "$(dirname "$0")/../confs/argocd-application.yaml"

log "Done. Check sync status with: kubectl get application -n argocd"
