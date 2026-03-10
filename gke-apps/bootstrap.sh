#!/usr/bin/env bash
set -euo pipefail

# Install Argo CD via helm so we can configure --insecure mode
# (TLS is terminated at the ingress; argocd-server speaks plain HTTP internally)
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --set "server.extraArgs[0]=--insecure" \
  --wait

# Bootstrap the app-of-apps
# Edit apps/root.yaml with your git repo URL before running this.
kubectl apply -f apps/root.yaml

echo ""
echo "Argo CD is up. Get the initial admin password:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "Port-forward until DNS propagates:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:80"
