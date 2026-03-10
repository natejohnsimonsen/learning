#!/usr/bin/env bash
set -euo pipefail

# Install Argo CD
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for argocd-server..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=120s

# Bootstrap the app-of-apps
# Edit apps/root.yaml with your git repo URL before running this.
kubectl apply -f apps/root.yaml

echo ""
echo "Argo CD is up. Get the initial admin password:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "Port-forward the UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
