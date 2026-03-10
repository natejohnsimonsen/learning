# VPC Network
module "vpc_network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.0"

  project_id   = var.project_id
  network_name = "${var.cluster_name}-network"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name           = "${var.cluster_name}-subnetwork"
      subnet_ip             = "10.0.0.0/20"
      subnet_region         = var.region
      subnet_private_access = true # Enables Private Google Access for GCP APIs without internet
    }
  ]

  # Alias IP ranges required by GKE VPC-native networking
  secondary_ranges = {
    "${var.cluster_name}-subnetwork" = [
      {
        range_name    = "${var.cluster_name}-pod-range"
        ip_cidr_range = "10.1.0.0/16"
      },
      {
        range_name    = "${var.cluster_name}-service-range"
        ip_cidr_range = "10.2.0.0/20"
      }
    ]
  }

  depends_on = [google_project_service.apis]
}

# Cloud Router -- required by Cloud NAT for egress routing
resource "google_compute_router" "cloud_router" {
  name    = "${var.cluster_name}-cloud-router"
  region  = var.region
  network = module.vpc_network.network_name
  project = var.project_id

  depends_on = [google_project_service.apis]
}

# Static external IP -- stable address for Grafana and external service allowlisting
resource "google_compute_address" "cloud_nat_address" {
  name    = "${var.cluster_name}-cloud-nat-address"
  region  = var.region
  project = var.project_id

  depends_on = [google_project_service.apis]
}

# Cloud NAT -- provides outbound internet for private GKE nodes and pods
module "cloud_nat" {
  source  = "terraform-google-modules/cloud-nat/google"
  version = "~> 5.0"

  project_id = var.project_id
  region     = var.region
  router     = google_compute_router.cloud_router.name

  nat_ips                            = [google_compute_address.cloud_nat_address.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config_enable = false
  log_config_filter = "ERRORS_ONLY"
}
