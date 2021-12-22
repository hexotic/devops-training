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
