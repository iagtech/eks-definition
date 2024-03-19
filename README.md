# SuperUser Example Repository

## Minimal Example

The original question was done on a cluster that doesn't use AWS CNI and instead opts for Calico.  This repository replicates the issue using a traditional EKS cluster that uses all AWS addons.

To run the example, simply run `terraform init` then `terraform apply`.  You'll be asked to supply a name for the VPC / EKS cluster.

## Original Question

I have a terraform setup where I create a new launch template and a node group.  Without the launch template everything works correctly. With the launch template, the nodes become ready but the node group never finishes creating.

`main.tf`
```
...

resource "aws_launch_template" "this" {
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type           = var.block_device_mappings.type
      volume_size           = var.block_device_mappings.size
      iops                  = var.block_device_mappings.iops
      kms_key_id            = var.block_device_mappings.kms_key_id
      encrypted             = var.block_device_mappings.encrypted
      delete_on_termination = var.block_device_mappings.delete_on_termination
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.tpl", {
    cluster_endpoint = var.cluster_endpoint
    certificate_authority_data = var.certificate_authority_data
    bootstrap_extra_args = "--use-max-pods false"
    cluster_name = var.cluster_name
  }))
}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_group_arn
  instance_types  = [var.instance_type]
  subnet_ids = [
    for subnet in var.subnets : subnet.id
  ]
  capacity_type = var.capacity_type

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  update_config {
    max_unavailable = 1
  }

  labels = var.node_group_labels

  dynamic "taint" {
    for_each = toset(var.node_group_taints)

    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }
}

...
```

`user_data.tpl`
```
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="/:/+++"

--/:/+++
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash

/etc/eks/bootstrap.sh --apiserver-endpoint '${cluster_endpoint}' --b64-cluster-ca '${certificate_authority_data}' ${bootstrap_extra_args} '${cluster_name}'

--/:/+++--
```

`kubectl get pods`
```
NAME                                          STATUS   ROLES    AGE   VERSION
ip-192-168-1-128.us-west-1.compute.internal   Ready    <none>   13m   v1.29.0-eks-5e0fdde
ip-192-168-1-140.us-west-1.compute.internal   Ready    <none>   13m   v1.29.0-eks-5e0fdde
ip-192-168-1-157.us-west-1.compute.internal   Ready    <none>   13m   v1.29.0-eks-5e0fdde
```

`kubectl describe node ip-192-168-1-128.us-west-1.compute.internal`
```
Name:               ip-192-168-1-128.us-west-1.compute.internal
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/instance-type=m5.4xlarge
                    beta.kubernetes.io/os=linux
                    failure-domain.beta.kubernetes.io/region=us-west-1
                    failure-domain.beta.kubernetes.io/zone=us-west-1a
                    k8s.io/cloud-provider-aws=cff041cdc91d38d182baa77beef8bf9f
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=ip-192-168-1-128.us-west-1.compute.internal
                    kubernetes.io/os=linux
                    node.kubernetes.io/instance-type=m5.2xlarge
                    topology.kubernetes.io/region=us-west-1
                    topology.kubernetes.io/zone=us-west-1a
Annotations:        alpha.kubernetes.io/provided-node-ip: 192.168.1.128
                    csi.volume.kubernetes.io/nodeid: {"csi.tigera.io":"ip-192-168-1-128.us-gov-west-1.compute.internal"}
                    node.alpha.kubernetes.io/ttl: 0
                    projectcalico.org/IPv4Address: 192.168.1.128/24
                    projectcalico.org/IPv4VXLANTunnelAddr: 10.42.7.192
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Thu, 14 Mar 2024 10:40:54 -0400
Taints:             <none>
Unschedulable:      false
Lease:
  HolderIdentity:  ip-192-168-1-128.us-west-1.compute.internal
  AcquireTime:     <unset>
  RenewTime:       Thu, 14 Mar 2024 10:54:21 -0400
Conditions:
  Type                 Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----                 ------  -----------------                 ------------------                ------                       -------
  NetworkUnavailable   False   Thu, 14 Mar 2024 10:41:24 -0400   Thu, 14 Mar 2024 10:41:24 -0400   CalicoIsUp                   Calico is running on this node
  MemoryPressure       False   Thu, 14 Mar 2024 10:52:09 -0400   Thu, 14 Mar 2024 10:40:54 -0400   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure         False   Thu, 14 Mar 2024 10:52:09 -0400   Thu, 14 Mar 2024 10:40:54 -0400   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure          False   Thu, 14 Mar 2024 10:52:09 -0400   Thu, 14 Mar 2024 10:40:54 -0400   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready                True    Thu, 14 Mar 2024 10:52:09 -0400   Thu, 14 Mar 2024 10:41:18 -0400   KubeletReady                 kubelet is posting ready status
Addresses:
  InternalIP:   192.168.1.128
  InternalDNS:  ip-192-168-1-128.us-west-1.compute.internal
  Hostname:     ip-192-168-1-128.us-west-1.compute.internal
Capacity:
  cpu:                16
  ephemeral-storage:  20959212Ki
  hugepages-1Gi:      0
  hugepages-2Mi:      0
  memory:             64333324Ki
  pods:               110
Allocatable:
  cpu:                15890m
  ephemeral-storage:  18242267924
  hugepages-1Gi:      0
  hugepages-2Mi:      0
  memory:             61334028Ki
  pods:               110
System Info:
  Machine ID:                 ec2821bfac66895c1abc29a47021fe76
  System UUID:                ec2821bf-ac66-895c-1abc-29a47021fe76
  Boot ID:                    356d15db-1436-4c45-af1e-6a668eddd8e0
  Kernel Version:             5.10.210-201.852.amzn2.x86_64
  OS Image:                   Amazon Linux 2
  Operating System:           linux
  Architecture:               amd64
  Container Runtime Version:  containerd://1.7.11
  Kubelet Version:            v1.29.0-eks-5e0fdde
  Kube-Proxy Version:         v1.29.0-eks-5e0fdde
ProviderID:                   aws:///us-west-1a/i-0874068c9ab354407
Non-terminated Pods:          (6 in total)
  Namespace                   Name                                 CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
  ---------                   ----                                 ------------  ----------  ---------------  -------------  ---
  calico-apiserver            calico-apiserver-5f98fdb745-cf4xg    0 (0%)        0 (0%)      0 (0%)           0 (0%)         12m
  calico-system               calico-node-6c98k                    0 (0%)        0 (0%)      0 (0%)           0 (0%)         13m
  calico-system               calico-typha-695fb789b5-sfq4n        0 (0%)        0 (0%)      0 (0%)           0 (0%)         13m
  calico-system               csi-node-driver-qtczs                0 (0%)        0 (0%)      0 (0%)           0 (0%)         13m
  ionic-system                tigera-operator-967f9fc76-tghqf      0 (0%)        0 (0%)      0 (0%)           0 (0%)         15m
  kube-system                 kube-proxy-cnlnc                     100m (0%)     0 (0%)      0 (0%)           0 (0%)         13m
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests   Limits
  --------           --------   ------
  cpu                100m (0%)  0 (0%)
  memory             0 (0%)     0 (0%)
  ephemeral-storage  0 (0%)     0 (0%)
  hugepages-1Gi      0 (0%)     0 (0%)
  hugepages-2Mi      0 (0%)     0 (0%)
Events:
  Type     Reason                   Age                From                   Message
  ----     ------                   ----               ----                   -------
  Normal   Starting                 13m                kube-proxy
  Normal   Synced                   13m                cloud-node-controller  Node synced successfully
  Normal   Starting                 13m                kubelet                Starting kubelet.
  Warning  InvalidDiskCapacity      13m                kubelet                invalid capacity 0 on image filesystem
  Normal   NodeHasSufficientMemory  13m (x2 over 13m)  kubelet                Node ip-192-168-1-128.us-west-1.compute.internal status is now: NodeHasSufficientMemory
  Normal   NodeHasNoDiskPressure    13m (x2 over 13m)  kubelet                Node ip-192-168-1-128.us-west-1.compute.internal status is now: NodeHasNoDiskPressure
  Normal   NodeHasSufficientPID     13m (x2 over 13m)  kubelet                Node ip-192-168-1-128.us-west-1.compute.internal status is now: NodeHasSufficientPID
  Normal   NodeAllocatableEnforced  13m                kubelet                Updated Node Allocatable limit across pods
  Normal   RegisteredNode           13m                node-controller        Node ip-192-168-1-128.us-west-1.compute.internal event: Registered Node ip-192-168-1-128.us-west-1.compute.internal in Controller
  Normal   NodeReady                13m                kubelet                Node ip-192-168-1-128.us-west-1.compute.internal status is now: NodeReady
```

What makes this more confounding is if I remove `--apiserver-endpoint '${cluster_endpoint}' --b64-cluster-ca '${certificate_authority_data}'` from the `.tpl` file, everything works without issue except the max pod count is wrong (it drops to 58 instead due to the instance type).

Notes:
- We are using Calico instead of the AWS Node CNI.  This is a requirement for the project so I am stuck with that.
- The only oddity that has stuck out thus far is when I run this without the above arguments, the taint populates, when I do it with the taint does not populate, but that might be a red herring.

Any suggestions are appreciated.