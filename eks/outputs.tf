output "cluster_name" {
  description = "GKE cluster name"
  value       = module.gke.name
}

output "cluster_endpoint" {
  description = "GKE cluster control plane endpoint"
  value       = module.gke.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster certificate authority data"
  value       = module.gke.ca_certificate
  sensitive   = true
}

output "node_pool_name" {
  description = "Default node pool name"
  value       = module.gke.node_pools_names
}

output "vpc_network_name" {
  description = "VPC network name"
  value       = module.vpc_network.network_name
}

output "subnetwork_name" {
  description = "GKE subnetwork name"
  value       = module.vpc_network.subnets_names[0]
}

output "cloud_nat_address" {
  description = "Static external IP of the Cloud NAT -- allowlist this in Grafana Cloud and other external services"
  value       = google_compute_address.cloud_nat_address.address
}

output "cloud_router_name" {
  description = "Cloud Router name"
  value       = google_compute_router.cloud_router.name
}

output "kubeconfig_command" {
  description = "gcloud command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${module.gke.name} --zone ${var.zone} --project ${var.project_id}"
}
