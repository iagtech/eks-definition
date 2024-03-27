data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
    arn = data.aws_caller_identity.current.arn
}

data "aws_iam_policy_document" "k8s_admin" {
    statement {
        actions = ["sts:AssumeRole"]
        effect  = "Allow"
        principals {
            identifiers = concat(
                [data.aws_iam_session_context.current.issuer_arn],
                var.cluster_admin_users
            )
            type = "AWS"
        }
    }
}

data "aws_iam_policy_document" "k8s_readonly" {
    count = length(var.cluster_readonly_users) > 0 ? 1 : 0

    statement {
        actions = ["sts:AssumeRole"]
        effect  = "Allow"
        principals {
            identifiers = var.cluster_readonly_users
            type = "AWS"
        }
    }
}

data "aws_iam_policy_document" "clusteraccess" {
    statement {
        actions = [
            "eks:DescribeCluster",
        ]
        resources = [module.eks.cluster_arn]
    }
}

resource "aws_iam_policy" "node_efs_policy" {
    name        = "${var.cluster_name}-efs-policy"
    path        = "/"
    description = "Policy for EFKS nodes to use EFS"

    policy = jsonencode({
        "Statement": [
            {
                "Action": [
                    "elasticfilesystem:DescribeMountTargets",
                    "elasticfilesystem:DescribeFileSystems",
                    "elasticfilesystem:DescribeAccessPoints",
                    "elasticfilesystem:CreateAccessPoint",
                    "elasticfilesystem:DeleteAccessPoint",
                    "ec2:DescribeAvailabilityZones"
                ],
                "Effect": "Allow",
                "Resource": "*",
                "Sid": ""
            }
        ],
        "Version": "2012-10-17"
    })
}

resource "aws_security_group" "eks" {
    name        = "${var.cluster_name}-efs"
    description = "Allow traffic"
    vpc_id      = var.vpc

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
}

resource "aws_security_group" "efs" {
    name        = "${var.cluster_name}-efs"
    description = "Allow traffic"
    vpc_id      = var.vpc

    ingress {
        description      = "nfs"
        from_port        = 2049
        to_port          = 2049
        protocol         = "TCP"
        cidr_blocks      = [var.vpc_cidr_block]
    }
}

locals {
    flattened_groups = {
        for k, v in var.cluster_node_groups: k => {
            ami_type                     = v.ami_type
            capacity_type                = v.capacity_type
            instance_types               = v.instance_types
            vpc_security_group_ids       = [aws_security_group.eks.id]
            iam_role_additional_policies = {
                AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
            }

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
        aws-ebs-csi-driver = {
            most_recent = true
        }
        aws-efs-csi-driver = {
            most_recent = true
        }
    }

    vpc_id                   = var.vpc
    subnet_ids               = var.vpc_private_subnets
    control_plane_subnet_ids = var.vpc_intra_subnets

    eks_managed_node_groups = local.flattened_groups
}

resource "aws_efs_file_system" "kube" {
    creation_token = "eks-efs"
    encrypted      = true
}

resource "aws_efs_mount_target" "mount" {
    for_each = toset(var.vpc_private_subnets)

    file_system_id  = aws_efs_file_system.kube.id
    subnet_id       = each.key
    security_groups = [aws_security_group.efs.id]
}

resource "aws_iam_role" "k8s_admin" {
    name               = replace("${var.cluster_name}-admin", "-", "_")
    assume_role_policy = data.aws_iam_policy_document.k8s_admin.json
}

resource "aws_iam_policy" "k8s_admin" {
    name   = "${var.cluster_name}-admin"
    path   = "/"
    policy = data.aws_iam_policy_document.clusteraccess.json
}

resource "aws_iam_role_policy_attachment" "k8s_admin" {
    role       = aws_iam_role.k8s_admin.name
    policy_arn = aws_iam_policy.k8s_admin.arn
}

resource "aws_iam_role" "k8s_readonly" {
    count = length(var.cluster_readonly_users) > 0 ? 1 : 0

    name               = replace("${var.cluster_name}-readonly", "-", "_")
    assume_role_policy = data.aws_iam_policy_document.k8s_readonly[0].json
}

resource "aws_iam_policy" "k8s_readonly" {
    count = length(var.cluster_readonly_users) > 0 ? 1 : 0

    name   = "${var.cluster_name}-readonly"
    path   = "/"
    policy = data.aws_iam_policy_document.clusteraccess.json
}

resource "aws_iam_role_policy_attachment" "k8s_readonly" {
    count = length(var.cluster_readonly_users) > 0 ? 1 : 0

    role       = aws_iam_role.k8s_readonly[0].name
    policy_arn = aws_iam_policy.k8s_readonly[0].arn
}

resource "aws_eks_access_entry" "k8s_admin" {
    cluster_name  = module.eks.cluster_name
    principal_arn = aws_iam_role.k8s_admin.arn
    type          = "STANDARD"
    depends_on    = [aws_iam_role.k8s_admin]
}

resource "aws_eks_access_policy_association" "k8s_admin" {
    cluster_name  = module.eks.cluster_name
    policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    principal_arn = aws_iam_role.k8s_admin.arn
    access_scope {
        type = "cluster"
    }
    depends_on = [aws_eks_access_entry.k8s_admin]
}

resource "aws_eks_access_entry" "readonly" {
    count = length(var.cluster_readonly_users) > 0 ? 1 : 0

    cluster_name  = module.eks.cluster_name
    principal_arn = aws_iam_role.k8s_readonly[0].arn
    type          = "STANDARD"
    depends_on    = [aws_iam_role.k8s_readonly]
}

resource "aws_eks_access_policy_association" "readonly" {
    count = length(var.cluster_readonly_users) > 0 ? 1 : 0

    cluster_name  = module.eks.cluster_name
    policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
    principal_arn = aws_iam_role.k8s_readonly[0].arn
    access_scope {
        type = "cluster"
    }
    depends_on = [aws_eks_access_entry.readonly]
}
