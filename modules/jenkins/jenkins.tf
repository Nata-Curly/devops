resource "helm_release" "jenkins" {
  name             = var.release_name
  repository       = var.chart_repo
  chart            = var.chart
  namespace        = var.namespace
  create_namespace = true
  version          = var.chart_version

  values = [file("${path.module}/values.yaml")]

  # Wait for all resources to be ready
  wait = true
  # Ensure controller uses the created service account so agent pods inherit IRSA
  set {
    name  = "controller.serviceAccount.create"
    value = "false"
  }
  set {
    name  = "controller.serviceAccount.name"
    value = var.service_account_name
  }
}
