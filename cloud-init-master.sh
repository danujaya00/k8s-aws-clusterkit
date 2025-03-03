#!/bin/bash

# Set hostname dynamically
sudo hostnamectl set-hostname $(curl -s http://169.254.169.254/latest/meta-data/hostname)

# Ensure the kubelet config directory exists
sudo mkdir -p /etc/systemd/system/kubelet.service.d/

# Modify Kubelet config
printf '[Service]\nEnvironment="KUBELET_EXTRA_ARGS=--node-ip=10.0.0.11"\n' | sudo tee /etc/systemd/system/kubelet.service.d/20-aws.conf

# Reload systemd and restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Initialize Kubernetes cluster
sudo kubeadm init --token-ttl 0 --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem > /root/kube-init.log 2>&1

# Setup kubeconfig for root user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Also make config available for other users
sudo mkdir -p /home/ubuntu/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Set KUBECONFIG variable  automatically in future shell sessions.
sudo su -
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile

# Save the join command for worker nodes
kubeadm token create --print-join-command > /root/kubeadm-join.sh
