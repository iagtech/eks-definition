variable "cluster_name" {
    type        = string
    description = "Name of the cluster"
    nullable    = false
}

variable "cluster_version" {
    type        = string
    description = "Version of the cluster"
    nullable    = false
}

variable "cluster_node_groups" {
    type        = map(object({
        ami_type                     = string
        capacity_type                = string
        instance_types               = list(string)
        volume_type                  = string
        volume_size                  = number
        volume_iops                  = optional(number)
        volume_kms_key_id            = optional(string)
        volume_encrypted             = optional(bool, false)
        volume_delete_on_termination = optional(bool, true)
        group_desired_size           = number
        group_min                    = number
        group_max                    = number
        group_max_unavailable        = number
    }))
    description = "A map of node group definitions to attach to the cluster"
    nullable    = false
}

variable "cluster_enable_public_access" {
    type        = string
    description = "Should the cluster's endpoint be publically accessible"
    nullable    = false
}

variable "cluster_admin_users" {
    type        = list(string)
    description = "ARNs of users to be granted admin access"
    nullable    = false
}

variable "cluster_readonly_users" {
    type        = list(string)
    description = "ARNs of users to be granted read only access"
    nullable    = false
}

variable "vpc" {
    type        = string
    description = "AWS VPC Object"
    nullable    = false
}

variable "vpc_cidr_block" {
    type        = string
    description = "CIDR Block of the created VPC"
    nullable    = false
}

variable "vpc_private_subnets" {
    type        = list(string)
    description = "AWS Private Subnet IDs"
    nullable    = false
}

variable "vpc_public_subnets" {
    type        = list(string)
    description = "AWS Public Subnet IDs"
    nullable    = false
}

variable "vpc_intra_subnets" {
    type        = list(string)
    description = "AWS Intra Subnet IDs"
    nullable    = false
}