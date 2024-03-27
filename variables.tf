// ===============================
// VPC Variables
// ===============================

variable "vpc_name" {
    type        = string
    description = "Name of the VPC"
    default     = "iag-qa"
}

variable "vpc_cidr_block" {
    type        = string
    description = "CIDR Block of the created VPC"
    default     = "10.0.0.0/16"
}

// ===============================
// Cluster Variables
// ===============================

variable "cluster_name" {
    type        = string
    description = "Name of the cluster"
    default     = "iag-qa"
}

variable "cluster_version" {
    type        = string
    description = "Version of the cluster"
    default     = "1.29"
}

variable "cluster_enable_public_access" {
    type        = bool
    description = "Should the cluster's endpoint be publically accessible"
    default     = true
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
    default     = {
        "node-group" = {
            ami_type                     = "AL2_x86_64"
            capacity_type                = "SPOT"
            instance_types               = ["r7i.xlarge"]
            volume_type                  = "gp2"
            volume_size                  = 20
            group_desired_size           = 1
            group_min                    = 1
            group_max                    = 5
            group_max_unavailable        = 1
        }
    }
}

variable "cluster_admin_users" {
    type        = list(string)
    description = "ARNs of users to be granted admin access"
    default     = []
}

variable "cluster_readonly_users" {
    type        = list(string)
    description = "ARNs of users to be granted read only access"
    default     = []
}