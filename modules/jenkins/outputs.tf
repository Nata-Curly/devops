output "jenkins_release_name" {
  value = helm_release.jenkins.name
}

output "jenkins_namespace" {
  value = helm_release.jenkins.namespace
}

# You can fetch admin password with kubernetes_secret data source if kubernetes provider configured
# data "kubernetes_secret" "jenkins_admin" {
#   metadata {
#     name      = "jenkins"
#     namespace = helm_release.jenkins.namespace
#   }
# }
# output "jenkins_admin_password" {
#   value = data.kubernetes_secret.jenkins_admin.data["jenkins-admin-password"]
#   sensitive = true
# }
