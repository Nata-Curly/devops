resource "helm_release" "aws_ebs_csi_driver" {
  name             = "aws-ebs-csi-driver"
  repository       = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart            = "aws-ebs-csi-driver"
  namespace        = "kube-system"
  create_namespace = false
  # version can be adjusted to a compatible chart version for your cluster
  version          = "1.6.0"

  # minimal values; adjust if you need custom IAM or node selectors
  values = [fileexists("${path.module}/aws_ebs_values.yaml") ? file("${path.module}/aws_ebs_values.yaml") : "[]"]
}
