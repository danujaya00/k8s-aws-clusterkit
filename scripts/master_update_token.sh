#!/bin/bash

# sleep for 30 seconds to allow the master to initialize
sleep 30

# Generate the join command from kubeadm
JOIN_CMD=$(kubeadm token create --print-join-command)

# Extract the token and the certificate hash
TOKEN=$(echo $JOIN_CMD | awk '{print $5}')
CERT_HASH=$(echo $JOIN_CMD | awk '{print $7}' | sed 's/sha256://')

# Retrieve the master node IP address
MASTER_IP=$(hostname -I | awk '{print $1}')

# Update SSM Parameter Store with the new token, hash, and master IP
aws ssm put-parameter --name "/kubeadm/join-token" --value "$TOKEN" --type "SecureString" --overwrite
aws ssm put-parameter --name "/kubeadm/discovery-hash" --value "$CERT_HASH" --type "SecureString" --overwrite
aws ssm put-parameter --name "/kubeadm/master-ip" --value "$MASTER_IP" --type "SecureString" --overwrite

echo "Updated SSM parameters with token, discovery hash, and master IP."
