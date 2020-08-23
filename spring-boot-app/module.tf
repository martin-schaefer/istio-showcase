# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Module for Spring Boot app standard deployment
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

variable "app_name" {
  type = string
}

variable "app_version" {
  type = string
}

variable "app_namespace" {
  type = string
}

variable "app_replicas" {
  type = number
  default = 1
}

variable "node_port" {
  type = number
}

resource "kubernetes_config_map" "spring-boot-app-config-map" {
  metadata {
    name = var.app_name
    namespace = var.app_namespace
  }

  data = {
    "application.yml" = "${file("./app-config/${var.app_name}.yml")}"
  }
}

resource "kubernetes_deployment" "spring-boot-app-deployment" {
  metadata {
    name = var.app_name
    namespace = var.app_namespace
  }
  spec {
    replicas = var.app_replicas
    selector {
      match_labels = {
        app = var.app_name
      }
    }
    template {
      metadata {
        labels = {
          app = var.app_name
          app_version = var.app_version
          fluentd-log-format = "spring-boot-json"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path" = "/actuator/prometheus"
          "prometheus.io/port" = "8010"
        }
      }
      spec {
        automount_service_account_token = true
        container {
          name  = "${var.app_name}-container"
          image = "gcr.io/handy-zephyr-272321/${var.app_name}:${var.app_version}"
          port {
            name = "http-service"
            container_port = 80
          }
          port {
            name = "http-management"
            container_port = 8010
          }
          resources {
            requests {
              cpu = "0.1"
              memory = ".5G"
            }
            limits {
              cpu = "1"
              memory = "1G"              
            }
          }
          readiness_probe {
            http_get {
              path = "/actuator/health"
              port = 8010
            }
            timeout_seconds = 5
            period_seconds = 30
            success_threshold = 1
            failure_threshold = 1
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "spring-boot-app-service" {
  metadata {
    name = var.app_name
    namespace = var.app_namespace
    labels = {
      sba-monitored = "true"
    }
  }
  spec {
    selector = {
      app = var.app_name
    }
    port {
      name = "http-service"
      port = 80
      node_port = var.node_port
    }
    port {
      name = "http-management"
      port = 8010
    }
    type = "NodePort"
  }
}
