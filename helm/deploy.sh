#!/usr/bin/env bash
set -euo pipefail

# Add Helm repos
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

NAMESPACE_CLOUD="monitoring"
NAMESPACE_LOCAL="observability"

# ============================================================
# Deploy Alloy -> Grafana Cloud
# ============================================================
deploy_cloud() {
  echo "Deploying Grafana Alloy (Grafana Cloud)..."

  # Required - fill these in or export them before running
  : "${GRAFANA_CLOUD_API_KEY:?Required}"
  : "${GRAFANA_CLOUD_PROMETHEUS_URL:?Required}"
  : "${GRAFANA_CLOUD_METRICS_USER:?Required}"
  : "${GRAFANA_CLOUD_LOKI_URL:?Required}"
  : "${GRAFANA_CLOUD_LOGS_USER:?Required}"
  : "${GRAFANA_CLOUD_TEMPO_ENDPOINT:?Required}"
  : "${GRAFANA_CLOUD_TEMPO_USER:?Required}"
  : "${GRAFANA_CLOUD_PROFILES_URL:?Required}"
  : "${GRAFANA_CLOUD_PROFILES_USER:?Required}"

  kubectl create namespace "$NAMESPACE_CLOUD" --dry-run=client -o yaml | kubectl apply -f -

  helm dependency update ./gke-alloy-cloud

  helm upgrade --install alloy-cloud ./gke-alloy-cloud \
    --namespace "$NAMESPACE_CLOUD" \
    --set grafanaCloud.apiKey="$GRAFANA_CLOUD_API_KEY" \
    --set grafanaCloud.prometheus.url="$GRAFANA_CLOUD_PROMETHEUS_URL" \
    --set grafanaCloud.prometheus.username="$GRAFANA_CLOUD_METRICS_USER" \
    --set grafanaCloud.loki.url="$GRAFANA_CLOUD_LOKI_URL" \
    --set grafanaCloud.loki.username="$GRAFANA_CLOUD_LOGS_USER" \
    --set grafanaCloud.tempo.endpoint="$GRAFANA_CLOUD_TEMPO_ENDPOINT" \
    --set grafanaCloud.tempo.username="$GRAFANA_CLOUD_TEMPO_USER" \
    --set grafanaCloud.profiles.url="$GRAFANA_CLOUD_PROFILES_URL" \
    --set grafanaCloud.profiles.username="$GRAFANA_CLOUD_PROFILES_USER" \
    --wait

  echo "Alloy (cloud) deployed to namespace: $NAMESPACE_CLOUD"
}

# ============================================================
# Deploy local Grafana stack
# ============================================================
deploy_local() {
  echo "Deploying local Grafana stack..."

  kubectl create namespace "$NAMESPACE_LOCAL" --dry-run=client -o yaml | kubectl apply -f -

  helm dependency update ./grafana-local-stack

  helm upgrade --install grafana-local ./grafana-local-stack \
    --namespace "$NAMESPACE_LOCAL" \
    --wait \
    --timeout 10m

  echo "Local stack deployed to namespace: $NAMESPACE_LOCAL"
  echo ""
  echo "Grafana URL:"
  kubectl get svc -n "$NAMESPACE_LOCAL" grafana-local-kube-prometheus-stack-grafana \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || \
    echo "  kubectl port-forward -n $NAMESPACE_LOCAL svc/grafana-local-kube-prometheus-stack-grafana 3000:80"
  echo ""
  echo "Default credentials: admin / admin"
}

case "${1:-}" in
  cloud) deploy_cloud ;;
  local) deploy_local ;;
  all)   deploy_cloud; deploy_local ;;
  *)
    echo "Usage: $0 [cloud|local|all]"
    echo ""
    echo "  cloud  - Deploy Alloy collector sending to Grafana Cloud"
    echo "  local  - Deploy full local observability stack"
    echo "  all    - Deploy both"
    ;;
esac
