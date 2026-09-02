#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# p3 - test.sh
# Verification commands matching what the subject/eval sheet checks.
# Run manually, step by step, during rehearsal or defense.
# ---------------------------------------------------------------------------

echo "--- Namespaces ---"
kubectl get ns

echo
echo "--- Pods in dev namespace ---"
kubectl get pods -n dev

echo
echo "--- Argo CD Application status ---"
kubectl get application -n argocd

echo
echo "--- Current app version (curl) ---"
curl -s http://localhost:8888/ || echo "(app not reachable yet - check port-forward / loadbalancer mapping)"

echo
echo "--- Argo CD admin password ---"
kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d
echo
