# Kubernetes Notes

# Introduction
Kubernetes is an orchestrator for containers (like docker swarm).<br>
Its main force is its ability to do **deployments**.

## Installation
* local developpement : `minikube`
* production env : `kubeadm`

### TP1 - Minikube installation
On AWS, it's best to use a **T2 large with 20 GB disk**.
<details>
<summary>
<b>CentOS install</b>
</summary>

```sh
#!/bin/bash
sudo yum -y update
sudo curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker centos
sudo systemctl start docker
sudo yum -y install epel-release
sudo yum -y install libvirt qemu-kvm virt-install virt-top libguestfs-tools bridge-utils
sudo yum install -y socat conntrack wget 
sudo wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 /usr/bin/minikube
sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
sudo chmod +x kubectl
sudo mv kubectl  /usr/bin/
sudo echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
sudo systemctl enable docker.service
```

</details>
<details>

<summary>
<b>Ubuntu install (20.04 LTS)</b>

</summary>

```sh
#!/bin/bash
sudo apt-get -y update
sudo curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
sudo systemctl start docker
# Install virtualisation tools
sudo apt install -y qemu qemu-kvm libvirt-daemon libvirt-clients bridge-utils virt-manager
sudo apt-get install -y socat conntrack wget
sudo wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 /usr/bin/minikube
sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
sudo chmod +x kubectl
sudo mv kubectl  /usr/bin/
# Activation of port forwarding
sudo echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
sudo systemctl enable docker.service
```
</details>

**Autocompletion**
```sh
# Add kubernetes auto completion
echo 'source <(kubectl completion bash)' >> ${HOME}/.bashrc
```

## Cluster start-up
```sh
# /!\ Not to be done as root !
minikube start --driver=none
```

### Good practices
One container per pod to avoid building monolithic applications and to avoid having to update the whole pod when only one container needs updating.

## TP2 - simple pod creation & misc commands
```sh
kubectl cluster-info

# Create a pod
kubectl run web --image nginx --port 80

kubectl describe pod web
kubectl logs web # when one container/pod
kubectl get pod -o wide
# kubectl port-forward <name> <host_port>:<container_port> --address 0.0.0.0
kubectl port-forward web 8080:80 --address 0.0.0.0
# will run in foreground

# kubectl delete web
```

# Replicaset
A replicaset is a mean to run a certain number of the same pods. Main advantages:

* `high availability` (pods are restarted to match the number of replicas)
* has `load balacing` built-in

## TP3 - Quick deployement of a replicaset
```sh
kubectl create deployment nginx-deployment --image nginx --port 80 --replicas=3
kubectl port-forward web 8080:80 --address 0.0.0.0
```

## TP4 - Use a manifest to deploy a simple pod
**NOTE**: several resources can be separated with `---`

`nginx-pod.yaml`
```yaml

apiVersion: v1
kind: Pod
metadata:
  name: simple-nginx-server
  labels:
    app: nginx
    env: prod
spec:
  containers:
  - name: nginx-chris
    image: nginx
    ports:
      - containerPort: 80
```

### Commands to intereact with a manifest
```sh
kubectl create -f nginx-pod.yaml
kubectl apply -f nginx-pod.yaml
kubectl delete -f nginx-pod.yaml
kubectl replace -f nginx-pod.yaml
```

# Environment variables

<table>
<tr>
<th> plain value </th>
<th> configMap </th>
<th> secret </th>
</tr>
<tr>
<td>
  
```yaml
env:
  name: APP_COLOR
  value: red
```

</td>
<td>

```yaml
apiVersion: v1
kind: ConfigMap
data:
  color: red
metadata:
  name: appcolor
---
  - env:
    - name: APP_COLOR
      valueFrom:
        configMapKeyRef:
          name: appcolor
          key:  color
```

</td>

<td>

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: appcolor
type: Opaque
data:  # echo -n red | base64
  color: cmVk
---
  - env:
    - name: APP_COLOR
      valueFrom:
        secretKeyRef:
          name: appcolor
          key:  color
```

</td>
  
</tr>
</table>

## TP5 - Env variables
### Using the command line
```sh
kubectl run  webapp  --image=kodekloud/webapp-color --port 8080 --env APP_COLOR=blue
kubectl port-forward webapp  8080:8080 --address 0.0.0.0
```
### Using a generated manifest (yaml output)
Use of:
* `--dry-run` : does not execute
* `-o yaml` : yaml output

```sh
kubectl run webapp-color --image=kodekloud/webapp-color --env APP_COLOR=red --dry-run=client -o yaml > webapp-pod.yaml
kubectl apply -f webapp-pod.yaml
```

## TP6 - deployment
Deployment manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-blue
  labels:
    role: webapp-blue
```

```sh
kubectl apply -f <manifest>
kubectl expose deployment/webapp-blue
```

## TP7 - configMap

### TP7 snippets
```sh
kubectl create configmap appcolor --from-literal=color=red -o yaml --dry-run=client
```

```sh
kubectl exec -it webapp -- /bin/sh
/opt # export
export APP_COLOR='red'
```

# Network

Different types:
* `NodePort`
* `ClusterIP`
* `LoadBalancer`

## TP8 - Service creation (with namespace)

### TP8 snippets

```sh
kubectl -n production apply -f .
kubectl get po -n production -o wide
kubectl describe svc -n production app-srv
kubectl describe svc nginx-svc
# Pay attention to the target port and endpoints
```
### Other commands
Service manifest from command line:
```sh
kubectl create deploy nginx --image nginx --port 80 --replicas=3
kubectl expose deploy/nginx --name nginx-svc --type NodePort --port 80 --dry-run=client -o yaml
```

# Storage
## Volumes
```yaml
spec:
  containers:
  - image: alpine
    volumeMounts:
    - mountPath: /opt
      name: data-volume
  volumes:
  - name: data-volume
    hostPath:
      path: /data
      type: Directory  # also DirectoryOrCreate
```

## Volumes / Storage
Pod -> PVC -> PV

## Persistent volumes
* No imperative command for creation

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-vol1
spec:
  accessModes:
    - ReadWriteOnce    # also possible: ReadOnlyMany, ReadWriteMany
  capacity:
    storage: 1Gi
  awsElasticBlockStore:
    volumeID: <volume-id>
    fsType: ext4
```
### Persistent Volume Claim (PVC)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
```

Beware of:
* accessModes
* storageClassName
* storage

## TP9 - persistent storage
### TP9 snippets
```sh
kubectl describe pod mysql
...
    Mounts:
      /opt from data-opt (rw)
      /var/lib/mysql from mysql-data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-l8pw2 (ro)
...
```

# Network management : ingress
Manages external access to the services in a cluster.

* Need to install the ingress controler:
`minikube addons enable ingress`

### Creation command
```sh
kubectl create ingress simple-fanout-ex --rule="foo.bar.com/foo*=service1:4200"
```

```yaml
metadata:
  name: ex-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$1  # fetch the path after domain name
```

# KubeConfig
```
kubectl config view   # same as cat ~/.kube/config
kubectl config use-context minikube # --kubeconfig=<config>
```
