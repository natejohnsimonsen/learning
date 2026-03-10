variable "project_id" {
  type        = string
  description = "Google Cloud project ID"
}

variable "cluster_name" {
  type        = string
  default     = "my-gke-cluster"
  description = "Name prefix applied to all Google Cloud resources"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Google Cloud region"
}

variable "zone" {
  type        = string
  default     = "us-central1-a"
  description = "Google Cloud zone (single-zone deployment for cost optimization)"
}
