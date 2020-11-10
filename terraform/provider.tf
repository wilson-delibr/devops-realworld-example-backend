
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = var.kubernetes_host
  token                  = data.google_client_config.default.access_token

  cluster_ca_certificate = base64decode(var.kubernetes_cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = var.kubernetes_host
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(var.kubernetes_cluster_ca_certificate)
    load_config_file       = false
  }
}