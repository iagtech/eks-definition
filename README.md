# Insurance Application Group Default EKS Setup

IAG, like many modern corporations, makes heavy use of containers and kubernetes in our infrastructure, particularly EKS.
Our default EKS setup is fairly basic but includes several features, including EBS and EFS support out of the box, as well
as support for creating ELBs on demand.  To that end, we have made a copy of our Terraform setup scripts available under an
MIT license.

## Requirements

You will need to install

- OpenTofu
- AWS CLI
- Kubectl
- Helm
- Eksctl
- Curl

in order to use these scripts

## Running

First init the provider with `tofu init`.  Once initialized, make any necessary customizations to the top level `variables.tf`
file.  Once ready, `tofu apply`.

> Note: It is necessary to maintain one directory per cluster.

## Contributing

This repository does not accept contributions.

## Authors

* **Ethan McGee** - *Initial work* - [ethantmcgee](https://github.com/ethantmcgee)

See also the list of [contributors](https://github.com/iagtech/dep-check/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/iagtech/dep-check/blob/main/LICENSE.md) file for details.

## Deploying an EBS App

```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-sc
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: centos
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo $(date -u) >> /data/out.txt; sleep 5; done"]
    volumeMounts:
    - name: persistent-storage
      mountPath: /data
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: ebs-claim
```

## Deploying an EFS App

```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: efs-app
spec:
  containers:
    - name: app
      image: centos
      command: ["/bin/sh"]
      args: ["-c", "while true; do echo $(date -u) >> /data/out; sleep 5; done"]
      volumeMounts:
        - name: persistent-storage
          mountPath: /data
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: efs-claim
```

## Deploying an Ingress Controller

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: maintenance
  labels:
    name: maintenance
spec:
  replicas: 1
  selector:
    matchLabels:
      app: maintenance
  template:
    metadata:
      labels:
        app: maintenance
    spec:
      containers:
      - name: maintenance
        image: wickerlabs/maintenance:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 9000
          name: web
---
apiVersion: v1
kind: Service
metadata:
  name: maintenance
spec:
  selector:
    app: maintenance
  ports:
    - port: 80
      targetPort: 9000
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: private
  labels:
    app: private
  annotations:
    nginx.ingress.kubernetes.io/use-forwarded-headers: "true"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=600
    alb.ingress.kubernetes.io/group.name: private
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: maintenance
            port:
              number: 80
```