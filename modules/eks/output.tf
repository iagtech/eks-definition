output "cluster_arn" {
    value = module.eks.cluster_arn
}

output "admin_arn" {
    value = aws_iam_role.k8s_admin.arn
}