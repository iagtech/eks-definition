resource "aws_iam_role" "role" {
    for_each = toset(["administrator", "read-only"])

    name = "${var.cluster_name}-${each.key}"

    # Just using for this example
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Sid    = "Example"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            },
        ]
    })
}

locals {
    flattened_groups = {
        for k, v in var.cluster_node_groups: k => {
            ami_type       = v.ami_type
            capacity_type  = v.capacity_type
            instance_types = v.instance_types

            min_size     = v.group_min
            max_size     = v.group_max
            desired_size = v.group_desired_size

            update_config = {
                max_unavailable = v.group_max_unavailable
            }

            block_device_mappings = {
                device_name = "/dev/xvda"

                ebs = {
                    volume_type           = v.volume_type
                    volume_size           = v.volume_size
                    iops                  = v.volume_iops
                    kms_key_id            = v.volume_kms_key_id
                    encrypted             = v.volume_encrypted
                    delete_on_termination = v.volume_delete_on_termination
                }
            }
        }
    }
}

module "eks" {
    source  = "terraform-aws-modules/eks/aws"
    version = "~> 20.0"

    cluster_name    = var.cluster_name
    cluster_version = var.cluster_version

    cluster_endpoint_public_access = var.cluster_enable_public_access

    cluster_addons = {
        coredns = {
            most_recent = true
        }
        kube-proxy = {
            most_recent = true
        }
        vpc-cni = {
            most_recent = true
        }
    }

    vpc_id                   = var.vpc
    subnet_ids               = var.vpc_private_subnets
    control_plane_subnet_ids = var.vpc_intra_subnets

    eks_managed_node_groups = local.flattened_groups
    access_entries          = {
        administrator = {
            kubernetes_groups = []
            principal_arn     = aws_iam_role.role["administrator"].arn

            policy_associations = {
                single = {
                    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
                    access_scope = {
                        type = "cluster"
                    }
                }
            }
        }

        read-only = {
            kubernetes_groups = []
            principal_arn     = aws_iam_role.role["read-only"].arn

            policy_associations = {
                single = {
                    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
                    access_scope = {
                        type = "cluster"
                    }
                }
            }
        }
    }
    
    enable_cluster_creator_admin_permissions = false
}