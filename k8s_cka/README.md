# Kubernetes notes

## Control plane
Collection of components responsible for managing the cluster:
* `kube-api-server`: k8s API
* `etcd`: backend data store for k8s cluster
* `kube-scheduler`: scheduler, assign container to worker node
* `kube-controller-manager`: variety of tasks related to automation
* `cloud-controller-manager`: provides an interface between k8s and various cloud platforms

## Nodes
Nodes are the machines where the containers managed by the cluster run.
* `kubelet`: agent that runs on each node, communicates with control plane.
* container runtime: not part of k8s but needed to run containers (**docker** or **containerd**)
* `kube-proxy`: is a network proxy. Runs on each node and provides networking between containers and services in the cluster

# Building a k8s cluster
`kubeadm`: tool to simplify the process of setting up a k8s cluster
* 3 servers: 1 control plane 2 for nodes
* ubuntu 18.04
* t3.medium

## server
* Change hostname and add private ip to `/etc/hosts`
```sh
sudo hostnamectl set-hostname k8s-control
sudo hostnamectl set-hostname k8s-worker1
sudo hostnamectl set-hostname k8s-worker2
```
* add ip to /etc/hosts

* Start required kernel modules
```sh
cat << EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
# start kernel modules now
sudo modprobe overlay
sudo modprobe br_netfilter
```
```sh
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
# Apply settings
sudo sysctl --system
```

* Install containerd
```sh
sudo apt-get update && sudo apt-get install -y containerd
# Create dir for containerd config files
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl status containerd
# Disable swap for containerd
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

* install K8s
```sh
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet=1.22.0-00 kubeadm=1.22.0-00 kubectl=1.22.0-00
sudo apt-mark hold kubelet kubeadm kubectl
```

## Cluster initialization

On control node:
```sh
sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version 1.22.0
# Set kubectl access
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
# get nodes
kubectl get nodes
```
```
NAME          STATUS     ROLES                  AGE   VERSION
k8s-control   NotReady   control-plane,master   45s   v1.22.0
```
=> **NotReady** as we need to install the network

## Install calico
```sh
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
kubectl get nodes
```
```
NAME          STATUS   ROLES                  AGE   VERSION
k8s-control   Ready    control-plane,master   11m   v1.22.0
```

## Add worker nodes to cluster
```sh
kubeadm token create --print-join-command
```
**Output**:
```sh
sudo kubeadm join 10.0.1.101:6443 --token 89j8j7.a7yfoq6tx5yk7wcu --discovery-token-ca-cert-hash sha256:58671aae52b14a6350cb403a6edd42cf51fac1bc58ffadbba7a8af332524f908
```
=> Copy/paste on nodes
<br>
Finally on control node:<br>
`kubectl get nodes`
```
NAME          STATUS   ROLES                  AGE   VERSION
k8s-control   Ready    control-plane,master   19m   v1.22.0
k8s-worker1   Ready    <none>                 57s   v1.22.0
```

# Namespaces
https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/

**Namespaces** provide a mechanism for isolating groups of resources within a single cluster. 

To see namespaces: <br>
`kubectl get namespaces`
```sh
NAME              STATUS   AGE
default           Active   73m
kube-node-lease   Active   73m
kube-public       Active   73m
kube-system       Active   73m
```
# Cluster Management
1. Intro to High availability
2. Intro to management tools
3. Draining a node
4. Upgrading with kubeadm
5. Backing up and restoring etcd cluster data

## High availability
* pattern 1
For high availability => multiple control planes `kube-api-server` => need load balancer to communicate with the k8s API
* pattern 2: stacked `etcd` : one `etcd` per control plane node
* pattern 3: external `etcd`: `etcd` running on different nodes

## Management tools
* `kubectl`: main method to interact woth k8s
* `kubeadm`: tool for creating clusters
* `minikube`: tool to quickly set up a single node cluster (dev / automation purposes)
* `helm`: provides templating and package management for k8s objects
* `Kompose`: helps translate Docker compose files into k8s objects.
* `Kustomize`: configuration management tool for managing k8s object configurations

## Safely draining a node
For maintenance purposes.
* `kubectl drain <node name>`
* `kubectl drain <node name> --ignore-daemonsets`
DeamonSets: pods that are tied to each node
* `kubectl uncordon <node name>`: when maintenance is complete, attach the node to the cluster
(uncordon does not make k8s move pods to the node automatically)

## Upgrading with kubeadm

### Control plane node
* upgrade kubeadm on the control plane node
* drain the control plane node
* plan the upgrade `kubeadm upgrade plan`
* apply the upgrade `kubeadm upgrade apply`
* upgrade `kubelet` and `kubectl` on the control plane node
* uncordon the control plane node

**Control plane upgrade**

```sh
sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=1.22.2-00
kubeadm version
kubectl drain k8s-control --ignore-daemonsets
sudo kubeadm upgrade plan v1.22.2
sudo kubeadm upgrade apply v1.22.2
sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubelet=1.22.2-00 kubectl=1.22.2-00
sudo systemctl daemon-reload
sudo systemctl restart kubelet
kubectl uncordon k8s-control
kubectl get nodes
```


### worker node upgrade
* drain the node
* upgrade `kubeadm`
* upgrade the kubelet configuration `kubeadm upgrade node`
* upgrade `kubelet` and `kubectl`

```sh
kubectl drain k8s-worker1 --ignore-daemonsets --force
sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubeadm=1.22.2-00
kubeadm version
sudo kubeadm upgrade node
sudo apt-get update && sudo apt-get install -y --allow-change-held-packages kubelet=1.22.2-00 kubectl=1.22.2-00
sudo systemctl daemon-reload
sudo systemctl restart kubelet
# On control plane node
# kubectl uncordon k8s-worker1
```

## Backing up and restoring etcd cluster data
```sh
ETCDCTL_API=3 etcdctl get cluster.name \
  --endpoints=https://10.0.1.101:2379 \
  --cacert=/home/cloud_user/etcd-certs/etcd-ca.pem \
  --cert=/home/cloud_user/etcd-certs/etcd-server.crt \
  --key=/home/cloud_user/etcd-certs/etcd-server.key

ETCDCTL_API=3 etcdctl snapshot save /home/cloud_user/etcd_backup.db \
  --endpoints=https://10.0.1.101:2379 \
  --cacert=/home/cloud_user/etcd-certs/etcd-ca.pem \
  --cert=/home/cloud_user/etcd-certs/etcd-server.crt \
  --key=/home/cloud_user/etcd-certs/etcd-server.key

sudo systemctl stop etcd
sudo rm -rf /var/lib/etcd  ###
```

**Restore process**
```sh
sudo ETCDCTL_API=3 etcdctl snapshot restore /home/cloud_user/etcd_backup.db \
  --initial-cluster etcd-restore=https://10.0.1.101:2380 \
  --initial-advertise-peer-urls https://10.0.1.101:2380 \
  --name etcd-restore \
  --data-dir /var/lib/etcd
sudo chown -R etcd:etcd /var/lib/etcd
sudo systemctl start etcd
```


```


# Commands recap
```sh
kubectl get nodes

kubectl get namespaces
kubectl create namespace <namespace>
kubectl get pods --namespace <namespace> # -n
kubectl get pods --all-namespaces

```