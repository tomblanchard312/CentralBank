variable "environment" {
  type = string
}

variable "role" {
  type = string
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "root_ca_key" {
  type      = string
  sensitive = true
}

variable "issuer_key" {
  type      = string
  sensitive = true
}

resource "kubernetes_deployment" "contracts" {
  metadata {
    name      = "centralbank-contracts"
    namespace = var.role
  }

  spec {
    replicas = var.environment == "prod" ? 2 : 1

    selector {
      match_labels = {
        app = "centralbank-contracts"
      }
    }

    template {
      metadata {
        labels = {
          app = "centralbank-contracts"
        }
      }

      spec {
        container {
          name  = "contracts"
          image = "centralbank/contracts:${var.image_tag}"

          env {
            name  = "CENTRALBANK_ENV"
            value = var.environment
          }

          env {
            name  = "CENTRALBANK_ROLE"
            value = var.role
          }

          env {
            name  = "CENTRALBANK_ROOT_CA_KEY"
            value = var.root_ca_key
          }

          env {
            name  = "CENTRALBANK_ISSUER_KEY"
            value = var.issuer_key
          }

          port {
            container_port = 8545  # Assuming Ethereum RPC port
          }

          resources {
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
            limits = {
              cpu    = "1000m"
              memory = "2Gi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "contracts" {
  metadata {
    name      = "centralbank-contracts"
    namespace = var.role
  }

  spec {
    selector = {
      app = "centralbank-contracts"
    }

    port {
      port        = 8545
      target_port = 8545
    }

    type = "ClusterIP"  # Internal only for CSP
  }
}

# Network policy for contracts (highly restricted)
resource "kubernetes_network_policy" "contracts" {
  metadata {
    name      = "contracts-network-policy"
    namespace = var.role
  }

  spec {
    pod_selector {
      match_labels = {
        app = "centralbank-contracts"
      }
    }

    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            app = "centralbank-api"
          }
        }
      }

      ports {
        port     = "8545"
        protocol = "TCP"
      }
    }

    egress {
      # Allow DNS
      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }

      ports {
        port     = "53"
        protocol = "UDP"
      }
    }
  }
}