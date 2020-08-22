# The istio system namespace
resource "kubernetes_namespace" "kiali-operator-namespace" {
  metadata {
    name = "kiali-operator"
  }
}

resource "helm_release" "kiali-operator" {
  name = "kiali-operator"
  repository = "https://kiali.org/helm-charts"
  chart = "kiali-operator"
  version = "1.22"
  namespace = "kiali-operator"
  set {
    name  = "cr.create"
    value = "false"
  }
  set {
    name  = "cr.namespace"
    value = "istio-system"
  }
  depends_on = [ kubernetes_namespace.kiali-operator-namespace ]
}