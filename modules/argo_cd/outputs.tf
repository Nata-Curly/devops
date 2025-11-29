output "argocd_release_name" {
  value = helm_release.argocd.name
}

output "argocd_namespace" {
  value = helm_release.argocd.namespace
}
