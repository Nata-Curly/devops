resource "kubernetes_config_map" "grafana_sample_dashboard" {
  metadata {
    name      = "grafana-sample-dashboard"
    namespace = var.namespace
    labels = {
      # this label is picked up by the grafana sidecar configured in values.yaml
      "grafana_dashboard" = "1"
    }
  }

  data = {
    "sample-dashboard.json" = <<-EOT
{
  "title": "Sample Overview",
  "uid": "sample-overview",
  "schemaVersion": 27,
  "version": 1,
  "panels": [],
  "annotations": {"list":[]},
  "time": {"from":"now-6h","to":"now"}
}
EOT
  }
}
