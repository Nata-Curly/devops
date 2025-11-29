resource "helm_release" "argocd" {
  name             = var.release_name
  repository       = var.chart_repo
  chart            = var.chart
  namespace        = var.namespace
  create_namespace = true
  version          = var.chart_version
  values = [file("${path.module}/values.yaml")]
  wait = true
}

# Optional: install additional Argo Applications using the small chart in charts/
resource "helm_release" "argocd_apps" {
  name             = "argocd-apps"
  chart            = "${path.module}/charts"
  namespace        = var.namespace
  create_namespace = false
  values = [file("${path.module}/charts/values.yaml")]
  depends_on = [helm_release.argocd]
}
