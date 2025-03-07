#!/bin/bash

# Update packages
sudo apt update -y

# Retrieve the join token, master IP, and certificate hash from SSM Parameter Store
TOKEN=$(aws ssm get-parameter --name "/kubeadm/join-token" --with-decryption --query "Parameter.Value" --output text)
MASTER_IP=$(aws ssm get-parameter --name "/kubeadm/master-ip" --with-decryption --query "Parameter.Value" --output text)
CERT_HASH=$(aws ssm get-parameter --name "/kubeadm/discovery-hash" --with-decryption --query "Parameter.Value" --output text)

# Join the Kubernetes cluster
sudo kubeadm join ${MASTER_IP}:6443 --token ${TOKEN} --discovery-token-ca-cert-hash sha256:${CERT_HASH}
