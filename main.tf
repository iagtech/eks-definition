module "vpc" {
    source = "./modules/vpc"

    vpc_name            = var.vpc_name
    vpc_cidr_block      = var.vpc_cidr_block
}

module "eks" {
    source = "./modules/eks"

    cluster_name                 = var.cluster_name
    cluster_version              = var.cluster_version
    cluster_enable_public_access = var.cluster_enable_public_access
    cluster_node_groups          = var.cluster_node_groups
    cluster_admin_users          = var.cluster_admin_users
    cluster_readonly_users       = var.cluster_readonly_users
    vpc                          = module.vpc.vpc
    vpc_private_subnets          = module.vpc.vpc_private_subnets
    vpc_public_subnets           = module.vpc.vpc_public_subnets
    vpc_intra_subnets            = module.vpc.vpc_intra_subnets
    vpc_cidr_block               = var.vpc_cidr_block
}

resource "null_resource" "eks_access" {
    provisioner "local-exec" {
        command = <<EOT
aws eks update-kubeconfig --name ${var.cluster_name} --role-arn ${module.eks.admin_arn}
echo <<EOF
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: ${module.eks.efs}
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  provisioningMode: efs-ap
  fileSystemId: ${module.eks.efs}
  directoryPerms: "777"
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3
EOF | kubectl apply -f -
        EOT
    }
}