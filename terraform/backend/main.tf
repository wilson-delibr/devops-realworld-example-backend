resource "kubernetes_namespace" "main" {
  metadata {
    annotations = {
      name = "example-annotation"
    }

    labels = {
      mylabel = "label-value"
    }

    name = "${lower(var.system)}-${lower(var.component)}"
  }
} 

resource "random_password" "password" {
  length      = 20
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1
}
resource "kubernetes_stateful_set" "mssql" {
  count            = var.ext_database ? 1 : 0
  wait_for_rollout = "true"
  metadata {
    annotations = {
      SomeAnnotation = "foobar"
    }

    labels = {
      k8s-app                           = "mssql"
      version                           = "2017-latest"
    }

    name = "mssql"
    namespace = kubernetes_namespace.main.metadata.0.name
  }

  spec {
    pod_management_policy  = "Parallel"
    replicas               = 1
    revision_history_limit = 5

    selector {
      match_labels = {
        k8s-app = "mssql"
      }
    }

    service_name = "mssql"

    template {
      metadata {
        labels = {
          k8s-app = "mssql"
        }

        annotations = {}
      }

      spec {
        container {
          name              = "mssql-server"
          image             = "mcr.microsoft.com/mssql/server:2017-latest"
          image_pull_policy = "IfNotPresent"
          env_from {
            secret_ref {
              name = "mssql"
            }
          }
          env {
            name  = "ACCEPT_EULA"
            value = "Y"
          }

          port {
            container_port = 1433
          }

          resources {
            limits {
              cpu    = "1"
              memory = "6Gi"
            }

            requests {
              cpu    = "100m"
              memory = "200Mi"
            }
          }

          volume_mount {
            name       = "mssql-data"
            mount_path = "/mssql-data"
            sub_path   = ""
          }

        }

        termination_grace_period_seconds = 300

      }
    }

    update_strategy {
      type = "RollingUpdate"

      rolling_update {
        partition = 1
      }
    }

    volume_claim_template {
      metadata {
        name = "mssql-data"
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "standard"

        resources {
          requests = {
            storage = "16Gi"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mssql" {
  count            = var.ext_database ? 1 : 0
  metadata {
    name      = "mssql"
    namespace = kubernetes_namespace.main.metadata.0.name
  }
  spec {
    selector = {
      k8s-app = "mssql"
    }
    port {
      port        = 1433
      target_port = 1433
    }
  }
}
resource "kubernetes_secret" "main" {
  metadata {
    name      = "mssql"
    namespace = kubernetes_namespace.main.metadata.0.name

  }

  data = {
    ASPNETCORE_Conduit_ConnectionString = var.ext_database ? "Server=tcp:mssql,1433;User ID=sa;Password=${random_password.password.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;" : "Filename=realworld.db"
    SA_PASSWORD = random_password.password.result
  }
}


resource "kubernetes_deployment" "backend" {
  depends_on = [ kubernetes_secret.main ]
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.main.metadata.0.name
    labels = {
      app = "backend"
    }
  }

  spec {
    replicas = var.pod_scale

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
        }
      }

      spec {
        container {
          image = "eu.gcr.io/${var.project}/devops-realworld-example-backend:${var.tag}"
          name  = "backend"

          env_from {
            secret_ref {
              name = "mssql"
            }
          }
          env {
            name  = "ASPNETCORE_Conduit_DatabaseProvider"
            value = var.ext_database ? "sqlserver" : "sqlite"

          }
          
          resources {
            requests {
              cpu    = "100m"
              memory = "512Mi"
            }
            limits {
              cpu    = "1"
              memory = "2Gi"
            }
          }

          readiness_probe {
            http_get {
              path = "/articles"
              port = 5000
            }
            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.main.metadata.0.name
  }
  spec {
    selector = {
      app = "backend"
    }
    session_affinity = "ClientIP"
    port {
      port        = 80
      target_port = 5000
    }

    type = "LoadBalancer"
  }
}