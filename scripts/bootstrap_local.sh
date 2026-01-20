#!/usr/bin/env bash
set -euo pipefail

# One-command bootstrap for local execution (AWS creds already configured)

cd iac/terraform
cp -n terraform.tfvars.example terraform.tfvars || true

terraform init
terraform apply -auto-approve

REGION=$(terraform output -raw region)
CLUSTER=$(terraform output -raw eks_cluster_name)

aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER"

echo "Cluster ready. Nodes:"
kubectl get nodes

ECR=$(terraform output -raw ecr_repository_url)
MONGO_IP=$(terraform output -raw mongo_private_ip)

cd ../../app
./scripts/push_to_ecr.sh --region "$REGION" --ecr "$ECR" --tag v1

cd ../k8s/overlays/dev
./deploy.sh --image "$ECR:v1" --mongo_ip "$MONGO_IP" --mongo_user "wizuser" --mongo_pass "wizpass"

echo "Ingress hostname:"
kubectl -n wiz get ingress wizapp -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo
