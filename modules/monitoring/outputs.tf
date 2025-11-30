output "namespace" {
  value       = var.namespace
  description = "Namespace where monitoring chart is installed"
}

output "grafana_service_name" {
  value       = "kube-prometheus-stack-grafana"
  description = "Grafana service name created by the chart"
}
