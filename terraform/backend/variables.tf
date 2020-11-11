
variable "tag" {
  description = "tag of the docker containter to start, same as gitref"
}

variable "pod_scale" {
  default = 2
}

variable "ext_database" {
  default     = true
  type        = bool
  description = "Set to true if you don't need an external DB"
}

variable kubernetes_host {}
variable kubernetes_cluster_ca_certificate {}