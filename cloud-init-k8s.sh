#!/bin/bash
set -euxo pipefail 

# Log output to file for debugging
exec > /var/log/k8s-ami-setup.log 2>&1

# Update system
sudo apt update -y
sudo apt upgrade -y

# Enable required kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter
echo -e "overlay\nbr_netfilter" | sudo tee /etc/modules-load.d/containerd.conf

# Configure sysctl settings for Kubernetes networking
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# Install dependencies
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# Add Containerd repo and install latest stable version
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
sudo apt install -y containerd.io

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Modify containerd config to enable SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd
sleep 5

# Check if containerd is running
if ! pgrep -x "containerd" > /dev/null; then
    echo "ERROR: containerd is NOT running!" >&2
    exit 1
fi

# Add the Kubernetes repository for Ubuntu 24.04
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install latest Kubernetes packages
sudo apt update -y
sudo apt install -y kubelet kubeadm kubectl

# Disable automatic updates for Kubernetes packages
sudo apt-mark hold kubelet kubeadm kubectl

# Final verification
if ! command -v kubeadm &> /dev/null || ! command -v kubectl &> /dev/null; then
    echo "ERROR: Kubernetes installation failed!" >&2
    exit 1
fi

# Install unzip if not already installed
sudo apt install unzip -y

# Install AWS CLI (system-wide)
if ! command -v aws &>/dev/null; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip /tmp/awscliv2.zip -d /tmp/
  sudo /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
fi

# Verify aws CLI availability
aws --version

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Mark cloud-init completion
touch /var/lib/cloud/instance/boot-finished

# Create a completion marker for Terraform
touch /tmp/k8s-setup-done

# Wait for Terraform to detect the completion
echo "Kubernetes setup complete. Shutting down in 30 seconds..."
sleep 12

# Shut down the instance after provisioning
sync
sudo shutdown -h now
