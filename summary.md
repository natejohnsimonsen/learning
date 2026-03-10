# Learning Cluster - Summary

## Infrastructure

### GKE Cluster
- **Project:** nate-gke-cluster-2025
- **Cluster:** my-gke-cluster
- **Type:** GKE Standard (private nodes)
- **Region:** us-central1
- **Zone:** us-central1-a (single zone, free control plane)
- **Nodes:** e2-medium (2 vCPU, 4GB RAM, 30GB pd-standard)
- **Autoscaling:** 1-10 nodes

### Networking
- **VPC Network:** my-gke-cluster-network
- **Subnetwork:** my-gke-cluster-subnetwork (10.0.0.0/20)
- **Pod range:** my-gke-cluster-pod-range (10.1.0.0/16)
- **Service range:** my-gke-cluster-service-range (10.2.0.0/20)
- **Cloud Router:** my-gke-cluster-cloud-router
- **Cloud NAT:** static external IP -- run `terraform output cloud_nat_address` to get it
- **Cloudflare:** point wildcard A record (`*`) to the ingress-nginx external IP

### Connect kubectl
```sh
gcloud container clusters get-credentials my-gke-cluster --zone us-central1-a --project nate-gke-cluster-2025
```

### Terraform
```sh
cd ~/Code/learning/eks
terraform init
terraform apply -var="project_id=nate-gke-cluster-2025"
```

---

## Cost Estimate (~$91/mo)

| Component | $/month |
|---|---|
| e2-medium nodes (autoscaling 1-10, ~3 typical) | ~$81 |
| 30GB pd-standard (per node) | ~$1.50/node |
| Cloud NAT | ~$33 |
| Static external IP | ~$3 |
| Control plane (zonal) | free |

---

## ArgoCD

### Bootstrap
```sh
# From gke-apps/bootstrap.sh
kubectl apply -n argocd -f gke-apps/apps/root.yaml
```

### Admin password
```sh
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```
Current password: `pCSojLAqYY8daA1z`

### Port forward
```sh
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Sync wave order
| Wave | App |
|---|---|
| -1 | cert-manager (installs CRDs) |
| 0 | ingress-nginx |
| 1 | all other apps |
| 2 | cluster-manifests (ClusterIssuer, ArgoCD ingress) |

---

## Installed Apps

| App | Namespace | Notes |
|---|---|---|
| cert-manager | cert-manager | TLS via Let's Encrypt, ClusterIssuers: letsencrypt-prod + letsencrypt-staging |
| ingress-nginx | ingress-nginx | Get external IP: `kubectl get svc ingress-nginx-controller -n ingress-nginx` |
| kube-prometheus-stack | monitoring | Prometheus, Grafana, Alertmanager |
| loki | monitoring | Log aggregation |
| tempo | monitoring | Distributed tracing |
| keda | keda | Event-driven autoscaling |
| chaos-mesh | chaos-mesh | Chaos engineering |
| jaeger | jaeger | Tracing UI |
| k6-operator | k6-operator | Load testing |
| otel-demo | otel-demo | OpenTelemetry demo app |
| podinfo | podinfo | Demo microservice |
| gitea | gitea | Self-hosted Git |
| minio | minio | Object storage |
| it-tools | it-tools | Developer utilities -- update hostname in apps/it-tools.yaml |
| excalidraw | excalidraw | Whiteboard -- update hostname in apps/excalidraw.yaml |

---

## Helm Charts

### gke-alloy-cloud
Sends metrics, logs, traces, and profiles to Grafana Cloud.

**Before installing**, fill in `helm/gke-alloy-cloud/values.yaml`:
- `grafanaCloud.apiKey` -- Cloud Access Policy token
- `grafanaCloud.prometheus.url` + `username`
- `grafanaCloud.loki.url` + `username`
- `grafanaCloud.tempo.endpoint` + `username`
- `grafanaCloud.profiles.url` + `username`

Get values from: grafana.com > My Account > [your stack] > Configure

```sh
helm dependency update ~/Code/learning/helm/gke-alloy-cloud
helm upgrade --install gke-alloy ~/Code/learning/helm/gke-alloy-cloud \
  -n monitoring --create-namespace \
  -f ~/Code/learning/helm/gke-alloy-cloud/values.yaml
```

### grafana-local-stack
Full self-hosted observability stack (Prometheus, Loki, Tempo, Pyroscope, Grafana). Alternative to gke-alloy-cloud for fully local observability.

---

## GitHub
- **Repo:** https://github.com/natejohnsimonsen/learning
- **Branch:** main

---

## Known Issues / TODOs

- [ ] Update `it-tools.yaml` hostname from `it-tools.your-domain.com`
- [ ] Update `excalidraw.yaml` hostname from `excalidraw.your-domain.com`
- [ ] ArgoCD CLI login blocked -- password is `pCSojLAqYY8daA1z` (from initial-admin-secret)
- [ ] cert-manager ClusterIssuer sync failure fixed in latest commit (wave ordering: cert-manager wave -1, cluster-manifests wave 2) -- needs ArgoCD hard refresh to re-sync
- [ ] Node pool shows 1 node instead of 5 -- `terraform apply` needed to fix autoscaling=false
- [ ] Cloudflare wildcard A record needs ingress-nginx external IP
