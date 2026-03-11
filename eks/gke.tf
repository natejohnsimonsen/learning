# GKE Standard Private Cluster
# Zonal (single zone) for free control plane.
# e2-standard-2 spot nodes, autoscaling 1-10.
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 31.0"

  project_id = var.project_id
  name       = var.cluster_name
  region     = var.region

  # Single zone keeps control plane free and avoids cross-zone traffic costs
  regional = false
  zones    = [var.zone]

  network    = module.vpc_network.network_name
  subnetwork = module.vpc_network.subnets_names[0]

  ip_range_pods     = "${var.cluster_name}-pod-range"
  ip_range_services = "${var.cluster_name}-service-range"

  # Private nodes route all egress through Cloud NAT
  enable_private_nodes    = true
  enable_private_endpoint = false

  # /28 CIDR for the GKE control plane -- must not overlap VPC ranges
  master_ipv4_cidr_block = "172.16.0.0/28"

  node_pools = [
    {
      name               = "fallback-on-demand"
      machine_type       = "e2-standard-2"
      autoscaling        = true
      min_count          = 1
      max_count          = 5
      initial_node_count = 1
      disk_size_gb       = 30
      disk_type          = "pd-standard"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      spot               = false
    },
    {
      name               = "spot-standard-4"
      machine_type       = "e2-standard-4"
      autoscaling        = true
      min_count          = 0
      max_count          = 20
      initial_node_count = 1
      disk_size_gb       = 30
      disk_type          = "pd-standard"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      spot               = true
    },
    {
      name               = "spot-n2d-4"
      machine_type       = "n2d-standard-4"
      autoscaling        = true
      min_count          = 0
      max_count          = 20
      initial_node_count = 0
      disk_size_gb       = 30
      disk_type          = "pd-standard"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      spot               = true
    }
  ]

  node_pools_taints = {
    all = []
    fallback-on-demand = [
      {
        key    = "on-demand-fallback"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    ]
  }

  deletion_protection = false

  depends_on = [module.cloud_nat]
}
