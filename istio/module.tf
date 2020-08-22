variable "namespace" {
    type = "string"
    default = "istio-system"
}

# Istio 1.7 operator must be installed
resource "null_resource" "istio" {
  provisioner "local-exec" {
    command = "istioctl operator init"
  }
}

# The application namespace
resource "kubernetes_namespace" "istio-system-namespace" {
  metadata {
    name = var.namespace
  }
  depends_on = [ null_resource.istio ]
}

# The IstioOperator configuration
resource "kubectl_manifest" "istio-operator" {
  yaml_body = templatefile("${path.module}/istio-operator.yml", { namespace=var.namespace } )
  depends_on = [ kubernetes_namespace.istio-system-namespace ]
}