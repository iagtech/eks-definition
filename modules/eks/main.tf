module "eks" {
    source  = "terraform-aws-modules/eks/aws"
    version = "20.8.3"

    cluster_name    = var.cluster_name
    cluster_version = var.cluster_version

    cluster_endpoint_public_access = var.enable_public_access

    cluster_addons = {
        coredns = {
            most_recent = true
        }
        kube-proxy = {
            most_recent = true
        }
    }

    vpc_id     = var.vpc
    subnet_ids = var.private_subnets

    eks_managed_node_group_defaults = {
        instance_types = var.instance_types
    }
    
    eks_managed_node_groups = var.managed_node_groups

    enable_cluster_creator_admin_permissions = true
    
    access_entries = var.access_entries
}