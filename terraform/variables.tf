
variable "tag" {
  description = "tag of the docker containter to start, same as gitref"
}

variable "pod_scale" {
  default = 2
}



variable kubernetes_host {}
variable kubernetes_cluster_ca_certificate {}