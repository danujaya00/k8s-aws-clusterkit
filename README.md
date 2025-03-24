# k8s-aws-clusterkit

An Infrastructure-as-Code (IaC) solution for deploying a fully functional Kubernetes cluster on AWS EC2 using Terraform. This project automates the provisioning of a secure, scalable, cloud-native Kubernetes environment with advanced networking and security features.

---

## 🛠️ Tech Stack & Details

| Category | Technology |
|----------|-----------|
| **Infrastructure** | ![Terraform](https://img.shields.io/badge/Terraform-1.2+-623CE4?style=flat-square&logo=terraform&logoColor=white) ![AWS](https://img.shields.io/badge/AWS%20EC2-Cloud-FF9900?style=flat-square&logo=amazon-aws&logoColor=white) |
| **Container Runtime** | ![Containerd](https://img.shields.io/badge/Containerd-Latest-22A0E8?style=flat-square&logo=linux&logoColor=white) |
| **Orchestration** | ![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30-326CE5?style=flat-square&logo=kubernetes&logoColor=white) ![kubeadm](https://img.shields.io/badge/kubeadm-Bootstrap-326CE5?style=flat-square&logo=kubernetes&logoColor=white) |
| **Networking** | ![Cilium](https://img.shields.io/badge/Cilium-CNI-F79646?style=flat-square&logo=cncf&logoColor=white) ![WireGuard](https://img.shields.io/badge/WireGuard-Encryption-88171A?style=flat-square&logo=wireguard&logoColor=white) |
| **Ingress** | ![NGINX](https://img.shields.io/badge/NGINX%20Ingress-Controller-009639?style=flat-square&logo=nginx&logoColor=white) |
| **Load Balancing** | ![ALB](https://img.shields.io/badge/AWS%20ALB-Application%20Load%20Balancer-FF9900?style=flat-square&logo=amazon-aws&logoColor=white) |
| **Package Management** | ![Helm](https://img.shields.io/badge/Helm-3.0+-0F1689?style=flat-square&logo=helm&logoColor=white) |
| **Credentials** | ![SSM Parameter Store](https://img.shields.io/badge/AWS%20SSM-Parameter%20Store-FF9900?style=flat-square&logo=amazon-aws&logoColor=white) |

### Quick Stats

| Metric | Value |
|--------|-------|
| **Master Nodes** | 1 (t2.medium) |
| **Worker Nodes** | 2-5 (t2.micro, auto-scaling) |
| **Pod CIDR** | 10.100.0.0/16 |
| **VPC CIDR** | 10.0.0.0/16 |
| **Kubernetes Version** | v1.30 |
| **Terraform Version** | >= 1.2.0 |
| **AWS Provider** | ~> 5.0 |

---

## Overview

**k8s-aws-clusterkit** is designed to streamline Kubernetes cluster deployment on AWS by leveraging Terraform modules to manage all infrastructure components. It features:

- **High-Performance Networking**: Cilium CNI for cloud-native networking and load balancing
- **Secure Communication**: WireGuard VPN for encrypted inter-node communication
- **Automated Cluster Setup**: Kubeadm-based initialization with automatic node joining
- **Load Balancing**: Application Load Balancer (ALB) with auto-scaling worker nodes
- **IAM Security**: Fine-grained IAM roles and policies for EC2 instances
- **Bastion Host**: Secure SSH gateway for accessing private cluster nodes
- **Ingress Management**: NGINX Ingress Controller for service exposure

## Architecture

### High-Level Design

```
┌─────────────────────────────────────────────────────────┐
│                        AWS VPC (10.0.0.0/16)            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐         ┌──────────────────┐      │
│  │   Public Subnet  │         │  Public Subnet   │      │
│  │  (10.0.16.0/24)  │         │  (10.0.32.0/24)  │      │
│  │  us-east-1a      │         │  us-east-1b      │      │
│  │                  │         │                  │      │
│  │  ┌────────────┐  │         │  ┌────────────┐  │      │
│  │  │   Bastion  │  │         │  │    ALB     │  │      │
│  │  │   Host     │  │         │  │            │  │      │
│  │  └────────────┘  │         │  └────────────┘  │      │
│  └──────────────────┘         └──────────────────┘      │
│           │                                             │
│           │ SSH Tunnel                                  │
│           ↓                                             │
│  ┌──────────────────────────────────────────────┐       │
│  │     Private Subnet (10.0.0.0/24)             │       │
│  │         us-east-1a                           │       │
│  │                                              │       │
│  │  ┌──────────────┐   ┌──────────────────┐     │       │
│  │  │   Master     │   │  Worker Nodes    │     │       │
│  │  │   Node       │   │  (ASG: 2-5)      │     │       │
│  │  │ (t2.medium)  │   │  (t2.micro)      │     │       │
│  │  └──────────────┘   └──────────────────┘     │       │
│  │                                              │       │
│  │  Cilium CNI + WireGuard Encryption           │       │
│  │  Pod CIDR: 10.100.0.0/16                     │       │
│  └──────────────────────────────────────────────┘       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Components

#### 1. **VPC Module** (`modules/vpc/`)
Manages AWS networking infrastructure:
- VPC with CIDR block `10.0.0.0/16`
- Public subnets for Bastion and ALB (us-east-1a, us-east-1b)
- Private subnet for Kubernetes cluster (us-east-1a)
- Internet Gateway for public subnet internet access
- NAT Gateway for private subnet outbound connectivity
- Route tables and associations

#### 2. **Security Groups Module** (`modules/security_groups/`)
Defines fine-grained network access controls:
- **Bastion SG**: SSH access from anywhere (0.0.0.0/0)
- **Master Node SG**: 
  - SSH from Bastion (port 22)
  - Kubernetes API (port 6443)
  - Cilium health checks (port 4240)
  - WireGuard VPN (port 51820/UDP)
  - Kubelet communication (ports 10250-10255)
  - Cilium VXLAN (ports 8472-8475/UDP)
- **Worker Node SG**: Similar restrictions as Master
- **AMI SG**: Temporary security group for AMI creation
- **ALB SG**: HTTP/HTTPS traffic routing

#### 3. **IAM Module** (`modules/iam/`)
Configures AWS identity and access management:
- **Master Node IAM Role**: EC2 instance permissions for cluster management
  - EC2 describe operations (instances, volumes, routes, etc.)
  - Route and security group management
  - SSM Parameter Store access for kubeadm token exchange
- **Worker Node IAM Role**: Similar permissions for worker nodes
- Instance profiles for EC2 instance attachment

#### 4. **EC2 Module** (`modules/ec2/`)
Manages EC2 instances and compute resources:

**Bastion Host**:
- Single EC2 instance in public subnet
- General purpose t2.micro instance
- Acts as SSH gateway to private cluster nodes

**Master Node**:
- t2.medium instance in private subnet
- Fixed private IP: 10.0.0.11
- Runs Kubernetes control plane components
- Cloud-init provisioning for cluster initialization
- Remote execution for script deployment

**Worker Nodes**:
- Auto Scaling Group with 2-5 t2.micro instances
- Launches from custom Kubernetes-configured AMI
- Automatic join to cluster via kubeadm
- Cluster autoscaler tags for dynamic scaling

**Custom AMI Creation**:
- Temporary EC2 instance provisioned with cloud-init
- Installs containerd, Kubernetes tools (kubeadm, kubectl, kubelet)
- Configures sysctl and kernel modules
- Creates snapshot as reusable AMI for worker nodes

#### 5. **SSH Module** (`modules/ssh/`)
Manages SSH key pair infrastructure:
- Generates RSA 4096-bit private key
- Creates AWS key pair
- Stores private key locally as `aws-kube-cluster.pem`

#### 6. **Load Balancer Module** (`modules/load_balancer/`)
Provides external traffic routing:
- Application Load Balancer (ALB)
- HTTP listener on port 80
- Target group for worker nodes
- Health checks (30s interval, 3 healthy/unhealthy threshold)
- Auto Scaling Group attachment for dynamic backend management
- Forwards traffic to NGINX Ingress Controller on port 30080

## Deployment Workflow

### 1. **Infrastructure Provisioning**
```bash
terraform init
terraform plan
terraform apply
```

This creates:
- VPC and networking infrastructure
- Security groups with proper ingress/egress rules
- IAM roles and instance profiles
- SSH key pair (stored as `aws-kube-cluster.pem`)
- Bastion host for secure access

### 2. **AMI Creation**
- Launches temporary instance with `cloud-init-k8s.sh`
- Installs containerd container runtime
- Installs Kubernetes components (kubeadm, kubectl, kubelet v1.30)
- Installs AWS CLI, Helm, and WireGuard
- Instance shuts down automatically after setup
- Creates AMI snapshot for reuse

### 3. **Cluster Initialization**
Master node executes `cloud-init-master.sh`:
- Sets hostname from EC2 metadata
- Configures kubelet with node-ip flag
- Initializes Kubernetes with `kubeadm init`
  - Pod CIDR: 10.100.0.0/16
  - Token TTL: 0 (tokens never expire)
- Installs WireGuard for encrypted networking
- Installs and configures Cilium CNI
  - Enables WireGuard encryption
  - Disables kube-proxy replacement
  - Configures cluster pool CIDR

### 4. **Worker Node Joining**
Master node runs `master_update_token.sh` (daily via cron):
- Generates new kubeadm join command
- Extracts token and certificate hash
- Stores credentials in AWS SSM Parameter Store
- Workers retrieve via `worker_data.sh`:
  - Fetches token, hash, and master IP from SSM
  - Executes kubeadm join with credentials

### 5. **Cluster Validation & Setup**
After all nodes are ready, deploys:
- NGINX Ingress Controller via Helm
- Configured as NodePort service (ports 30080/30443)
- ALB targets ingress controller for traffic routing

## File Structure

```
.
├── main.tf                          # Root module composition
├── variables.tf                     # Root variables
├── outputs.tf                       # Root outputs (empty)
├── providers.tf                     # AWS provider configuration
│
├── modules/
│   ├── vpc/
│   │   ├── main.tf                  # VPC, subnets, IGW, NAT, routes
│   │   ├── variables.tf             # VPC variables
│   │   └── outputs.tf               # VPC outputs
│   │
│   ├── security_groups/
│   │   ├── main.tf                  # Security group definitions (full)
│   │   ├── variables.tf             # SG variables
│   │   └── output.tf                # SG outputs
│   │
│   ├── iam/
│   │   ├── main.tf                  # IAM roles and policies
│   │   ├── variables.tf             # IAM variables
│   │   └── output.tf                # IAM outputs
│   │
│   ├── ec2/
│   │   ├── bastion.tf               # Bastion host instance
│   │   ├── master.tf                # Master node + setup
│   │   ├── worker.tf                # Worker ASG + validation
│   │   ├── node_ami.tf              # AMI creation process
│   │   ├── variables.tf             # EC2 variables
│   │   └── outputs.tf               # EC2 outputs
│   │
│   ├── ssh/
│   │   ├── main.tf                  # SSH key pair generation
│   │   ├── variables.tf             # SSH variables
│   │   └── output.tf                # SSH outputs
│   │
│   ├── load_balancer/
│   │   ├── main.tf                  # ALB + target groups
│   │   ├── variables.tf             # ALB variables
│   │   └── output.tf                # ALB outputs
│
└── scripts/
    ├── cloud-init-k8s.sh            # AMI node preparation
    ├── cloud-init-master.sh         # Master node initialization
    ├── worker_data.sh               # Worker node join script
    └── master_update_token.sh       # Daily token rotation
```

## Key Features

### Security
- **Network Segmentation**: Public bastion separates internet from private cluster
- **Security Groups**: Minimal required ports per component
- **WireGuard Encryption**: Pod-to-pod encrypted communication
- **IAM Least Privilege**: Roles limited to necessary EC2 operations
- **SSH Key Management**: Automatic key generation and local storage

### High Availability
- **Multi-AZ**: Public subnets span us-east-1a and us-east-1b
- **Auto Scaling**: Worker nodes scale from 2 to 5 instances
- **ALB**: Distributes traffic across healthy worker nodes
- **Token Rotation**: Daily kubeadm token refresh prevents expiration

### Cloud-Native Networking
- **Cilium CNI**: Advanced networking and load balancing
- **WireGuard**: Low-overhead encrypted tunneling
- **Pod CIDR**: 10.100.0.0/16 for flexible pod networking
- **Health Checks**: Cilium monitoring on port 4240

### Automation
- **Cloud-Init**: Fully automated EC2 provisioning
- **Kubeadm**: Standard Kubernetes bootstrap tool
- **SSM Parameter Store**: Secure credential exchange between nodes
- **Helm**: Package manager for cluster add-ons
- **Cron Jobs**: Automated token management

## Prerequisites

### Local Requirements
- Terraform >= 1.2.0
- AWS CLI v2 configured with appropriate credentials
- SSH client for accessing cluster nodes
- kubectl configured to access cluster (after deployment)

### AWS Requirements
- AWS account with EC2, VPC, IAM, and ALB permissions
- Region set to `us-east-1` (default, configurable in `variables.tf`)
- Valid Ubuntu 24.04 LTS AMI in target region (default: ami-04b4f1a9cf54c11d0)

## Configuration

### Variables

**Root variables** (`variables.tf`):
```terraform
variable "region" {
  default = "us-east-1"
  # AWS region for all resources
}

variable "cluster_name" {
  default = "k8s-cluster"
  # Kubernetes cluster name (used for tagging)
}
```

**EC2 Module** - Customizable instance types:
```terraform
master_instance_type = "t2.medium"   # Master node size
worker_instance_type = "t2.micro"    # Worker node size
general_ami_id = "ami-04b4f1a9cf54c11d0"  # Base Ubuntu 24.04 AMI
```

**VPC Module** - Network configuration:
```terraform
vpc_cidr = "10.0.0.0/16"          # Main VPC CIDR
# Subnets automatically created within this range
```

**Kubernetes** - Pod networking:
- Pod CIDR: `10.100.0.0/16` (configured in master cloud-init)
- Cilium: WireGuard encryption enabled

### Customization

To modify the cluster:

1. **Change instance types**: Edit `main.tf` module `ec2` block
2. **Scale worker nodes**: Edit `worker.tf` ASG `desired_capacity`, `min_size`, `max_size`
3. **Change region**: Modify `region` variable in `variables.tf`
4. **Adjust pod CIDR**: Update `--pod-network-cidr` in `cloud-init-master.sh`
5. **Modify security rules**: Edit security group ingress/egress in `modules/security_groups/main.tf`

## Deployment Instructions

### 1. Prepare Environment

```bash
# Clone repository
git clone <repository-url>
cd k8s-aws-clusterkit

# Configure AWS credentials
export AWS_REGION=us-east-1
export AWS_ACCESS_KEY_ID=<your-key>
export AWS_SECRET_ACCESS_KEY=<your-secret>

# Verify AWS CLI
aws ec2 describe-regions --region-names us-east-1
```

### 2. Initialize Terraform

```bash
terraform init
```

This downloads required provider plugins and initializes the working directory.

### 3. Plan Deployment

```bash
terraform plan -out=cluster.plan
```

Review the plan to ensure all resources will be created correctly.

### 4. Apply Configuration

```bash
terraform apply cluster.plan
```

This will:
1. Create VPC and networking (~2-3 minutes)
2. Create security groups and IAM roles (~1 minute)
3. Generate SSH key pair (stored as `aws-kube-cluster.pem`)
4. Launch bastion host (~2-3 minutes)
5. Create AMI instance and provision Kubernetes tools (~10-15 minutes)
6. Create AMI snapshot (~5 minutes)
7. Launch master node and initialize cluster (~10-15 minutes)
8. Launch worker nodes and join cluster (~10-15 minutes)
9. Deploy NGINX Ingress Controller (~5 minutes)

**Total deployment time**: ~45-75 minutes

### 5. Access the Cluster

```bash
# Get master node IP
MASTER_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ec2-cluster-k8s-master" \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
  --output text)

# Get bastion public IP
BASTION_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ssh-bastion" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

# SSH to master via bastion
ssh -i aws-kube-cluster.pem \
    -J ubuntu@${BASTION_IP} \
    ubuntu@${MASTER_IP}

# On master node, verify cluster
kubectl get nodes
kubectl get pods --all-namespaces
```

### 6. Configure Local kubectl

```bash
# Copy kubeconfig from master node
ssh -i aws-kube-cluster.pem \
    -J ubuntu@${BASTION_IP} \
    ubuntu@${MASTER_IP} \
    "cat /etc/kubernetes/admin.conf" > ~/.kube/config-aws

# Set permissions
chmod 600 ~/.kube/config-aws

# Verify cluster access
export KUBECONFIG=~/.kube/config-aws
kubectl get nodes
```

## Post-Deployment

### Verify Cluster Health

```bash
# Check nodes
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system
kubectl get pods -n kube-flannel

# Check Cilium
kubectl get pods -n kube-system -l k8s-app=cilium
kubectl get pods -n kube-system -l k8s-app=cilium-operator

# Check Ingress Controller
kubectl get pods -n ingress-nginx
kubectl get ingress --all-namespaces
```

### Network Testing

```bash
# Test pod-to-pod communication
kubectl run test-pod --image=busybox --rm -it -- /bin/sh
# Inside pod: ping <other-pod-ip>

# Test DNS
kubectl run test-dns --image=busybox --rm -it -- /bin/sh
# Inside pod: nslookup kubernetes.default
```

### Deploy Sample Application

```bash
# Create nginx deployment
kubectl create deployment nginx --image=nginx:latest
kubectl expose deployment nginx --port=80 --type=NodePort

# Create ingress
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: nginx.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
EOF

# Access via ALB
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names k8s-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text)
echo "ALB DNS: ${ALB_DNS}"
```

## Cleanup

### Destroy Resources

```bash
# Destroy all Terraform-managed resources
terraform destroy

# Verify destruction
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value' --output text
```

### Manual Cleanup (if needed)

```bash
# Remove SSH key locally
rm aws-kube-cluster.pem

# Clear AWS CLI credentials
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
```

## Troubleshooting

### Master Node Fails to Initialize

**Symptoms**: Master node stuck in "initializing"

**Solutions**:
```bash
# SSH to master via bastion
ssh -i aws-kube-cluster.pem \
    -J ubuntu@${BASTION_IP} \
    ubuntu@${MASTER_IP}

# Check cloud-init logs
sudo tail -f /var/log/k8s-master-init.log

# Check kubeadm initialization
sudo tail -f /root/kube-init.log

# Manually check kubeadm status
sudo kubeadm status
```

### Worker Nodes Fail to Join

**Symptoms**: Worker nodes remain NotReady

**Solutions**:
```bash
# Check worker node cloud-init
sudo tail -f /var/log/worker-data.log

# Verify kubeadm join command
sudo kubeadm token list

# Get new join command
kubeadm token create --print-join-command

# Manually join worker
sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

### Cilium Pod Network Issues

**Symptoms**: Pods cannot communicate

**Solutions**:
```bash
# Check Cilium pods
kubectl get pods -n kube-system -l k8s-app=cilium

# Check Cilium status
kubectl exec -n kube-system <cilium-pod-name> -- cilium status

# Check WireGuard tunnels
kubectl exec -n kube-system <cilium-pod-name> -- ip link show type wireguard
```

### ALB Not Routing Traffic

**Symptoms**: Cannot access applications via ALB

**Solutions**:
```bash
# Check ALB health
aws elbv2 describe-target-health \
  --target-group-arn <TARGET_GROUP_ARN>

# Check NGINX ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx <nginx-controller-pod>

# Verify ingress configuration
kubectl describe ingress <ingress-name>
```

### SSH Connection via Bastion Times Out

**Symptoms**: Cannot SSH through bastion host

**Solutions**:
```bash
# Verify bastion security group
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=ssh-bastion"

# Check bastion network connectivity
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ssh-bastion" \
  --query 'Reservations[0].Instances[0].[PrivateIpAddress,PublicIpAddress]'

# Test SSH connection to bastion directly
ssh -i aws-kube-cluster.pem ubuntu@<BASTION_PUBLIC_IP>
```

## Performance Considerations

### Master Node Sizing
- **t2.medium**: Suitable for clusters up to 100 nodes
- For production clusters > 100 nodes, use **t3.large** or higher

### Worker Node Sizing
- **t2.micro**: Development/testing only (limited resources)
- For production: **t3.small** or **t3.medium** minimum

### Network Throughput
- Cilium + WireGuard introduces minimal overhead (~5% latency)
- VXLAN fallback available if performance critical

### Storage
- Cluster uses in-memory storage only (no EBS volumes)
- Add EBS drivers for persistent volume support if needed

## Security Best Practices

### Before Production Deployment

1. **Enable AWS CloudTrail**: Log all API calls
2. **Enable VPC Flow Logs**: Monitor network traffic
3. **Use AWS Secrets Manager**: Store sensitive data
4. **Enable EC2 detailed monitoring**: Track instance metrics
5. **Implement Pod Security Standards**: Enforce container policies
6. **Set up RBAC**: Limit user/service account permissions
7. **Enable audit logging**: Track Kubernetes API access
8. **Use Network Policies**: Restrict pod-to-pod communication

### Networking Security

```bash
# Example network policy (deny-all ingress)
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF
```

### RBAC Configuration

```bash
# Create limited-access user
kubectl create serviceaccount limited-user -n default
kubectl create rolebinding limited-role \
  --clusterrole=view \
  --serviceaccount=default:limited-user
```

## Advanced Topics

### Custom Pod CIDR

Modify `/scripts/cloud-init-master.sh`:
```bash
kubeadm init --pod-network-cidr=10.200.0.0/16 ...
```

And `/modules/ec2/master.tf` Cilium config.

### Multiple Availability Zones

Extend VPC module to create subnets in multiple AZs, update worker ASG zone identifiers.

### Private Container Registry

Add Amazon ECR configuration to cloud-init scripts and Kubernetes ImagePullSecrets.

### Monitoring and Logging

Install Prometheus, Grafana, and ELK stack:
```bash
# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add elastic https://helm.elastic.co

# Deploy monitoring
helm install prometheus prometheus-community/prometheus
helm install elasticsearch elastic/elasticsearch
```


## Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Cilium Documentation](https://docs.cilium.io/)
- [WireGuard](https://www.wireguard.com/)
- [kubeadm Documentation](https://kubernetes.io/docs/reference/setup-tools/kubeadm/)
- [AWS VPC Guide](https://docs.aws.amazon.com/vpc/)

