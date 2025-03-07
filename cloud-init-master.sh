#!/bin/bash
set -euxo pipefail

# Log output for debugging
exec > /var/log/k8s-master-init.log 2>&1

# Set hostname dynamically
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
sudo hostnamectl set-hostname $(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/hostname)

# Ensure the kubelet config directory exists
sudo mkdir -p /etc/systemd/system/kubelet.service.d/

# Modify Kubelet config safely
printf '[Service]\nEnvironment="KUBELET_EXTRA_ARGS=--node-ip=10.0.0.11"\n' | sudo tee /etc/systemd/system/kubelet.service.d/20-aws.conf

# Reload systemd and restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet || true 

# Ensure containerd is running before proceeding
if ! pgrep -x "containerd" > /dev/null; then
    echo "ERROR: containerd is NOT running!" >&2
    exit 1
fi

# Verify Kubernetes binaries are installed
if ! command -v kubeadm &> /dev/null || ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubeadm or kubectl is missing!" >&2
    exit 1
fi

# Initialize Kubernetes
for i in {1..3}; do
    sudo kubeadm init --pod-network-cidr=10.100.0.0/16  --token-ttl 0  --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem > /root/kube-init.log 2>&1 && break
    echo "Retrying kubeadm init ($i)..."
    sleep 10
done

# Setup kubeconfig for root user
if [ -f "/etc/kubernetes/admin.conf" ]; then
    export HOME="/root" 

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    # Also make config available for ubuntu user
    sudo mkdir -p /home/ubuntu/.kube
    sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
    sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

    # Ensure kubeconfig is accessible to the current user
    sudo chown ubuntu:ubuntu /etc/kubernetes/admin.conf
    sudo chmod 644 /etc/kubernetes/admin.conf
    
fi

# Set KUBECONFIG automatically in future shell sessions
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" | sudo tee -a /root/.bashrc /home/ubuntu/.bashrc

# Save the join command for worker nodes
kubeadm token create --print-join-command > /root/kubeadm-join.sh || true

# install Cilium CNI
helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium --namespace kube-system \
  --set containerRuntime.socketPath=/run/containerd/containerd.sock \
  --set kubeProxyReplacement=true \
  --set ipam.operator.clusterPoolIPv4PodCIDRList="10.100.0.0/16"


while [ ! -f /root/scripts/master_update_token.sh]; do sleep 1; done

# Copy the script to the correct location
sudo cp /root/scripts/master_update_token.sh /etc/cron.daily/master_update_token.sh
sudo chmod +x /etc/cron.daily/master_update_token.sh

# Ensure the script runs daily
sudo ln -s /etc/cron.daily/master_update_token.sh /etc/cron.d/master_update_token

# Run the script immediately
sudo /etc/cron.daily/master_update_token.sh

# Mark cloud-init completion
touch /var/lib/cloud/instance/boot-finished

# Ensure script finishes before Cloud-Init marks completion
sync
