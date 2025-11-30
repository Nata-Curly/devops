resource "helm_release" "kube_prometheus" {
  name             = var.chart
  repository       = var.chart_repo
  chart            = var.chart
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [
    replace(file("${path.module}/values.yaml"), "${GRAFANA_ADMIN_PASSWORD}", var.grafana_admin_password)
  ]

  depends_on = []
}
