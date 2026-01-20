<<<<<<< HEAD
# wiz-exercise
=======
# Wiz Technical Exercise v4 (AWS) — Complete, Deployable Project

Owner: **Nfua Tati**  
Generated: **2025-12-30**

This repository implements the **Wiz Technical Exercise v4** end-to-end on **AWS** using:
- **Terraform** for Infrastructure-as-Code (IaC)
- **EKS** for Kubernetes (cluster in **private subnets**)
- **EC2 VM** running **MongoDB 5.0** on **Ubuntu 20.04** (intentionally 1+ year old)
- **S3** bucket for daily automated backups (**public read + public listing**, intentionally insecure)
- **ALB Ingress** (AWS Load Balancer Controller) to expose the app publicly
- **GitHub Actions** CI/CD (IaC pipeline + App pipeline) with IaC and container scanning
- **CloudTrail + GuardDuty** for detective controls, and **EKS private endpoint + control plane logging** as preventive controls

## What the panel will be able to see in your demo
- Terraform deploys VPC, EKS, EC2 MongoDB VM, S3, ECR, CloudTrail, GuardDuty
- Web application works via public Ingress (ALB) and stores/retrieves data from MongoDB
- The app uses MongoDB connectivity configured via Kubernetes environment variable (**MONGO_URI**)
- Container contains `/wizexercise.txt` with your name (Nfua Tati) and you can prove it exists in the running container
- Application pod has **cluster-admin** privileges (intentional misconfiguration)
- MongoDB is restricted by Security Group to **Kubernetes node security group only**, and requires authentication
- MongoDB backups run daily to S3, and the bucket is **publicly listable** and **readable**

---

# 1) Prerequisites

## Workstation tools
Install these locally:
- Terraform 1.6+
- AWS CLI v2
- kubectl 1.27+ (any recent version works)
- Docker
- Helm 3

## AWS credentials
Configure AWS credentials locally:
```bash
aws configure
aws sts get-caller-identity
```

You need permissions to create:
- VPC, EKS, EC2, IAM, S3, ECR, CloudTrail, GuardDuty

## GitHub (for CI/CD)
If you will use GitHub Actions:
- Create a GitHub repo and push this code
- Configure **OIDC** role (instructions in `docs/github-oidc.md`)
- Add repo secrets if you choose not to use OIDC (not recommended)

---

# 2) Deploy (End-to-End)

## Step A — Configure Terraform variables
Copy example vars:
```bash
cd iac/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set at minimum:
- `project_name`
- `region`
- `allowed_ssh_cidr` (use your public IP/32 for safety during demo)

## Step B — Terraform apply
```bash
terraform init
terraform apply -auto-approve
```

Terraform outputs:
- EKS cluster name
- Mongo private IP
- S3 bucket name
- ECR repository URL

## Step C — Configure kubeconfig
```bash
aws eks update-kubeconfig --region $(terraform output -raw region) --name $(terraform output -raw eks_cluster_name)
kubectl get nodes
```

## Step D — Install AWS Load Balancer Controller
Terraform already installs it using Helm.
Verify:
```bash
kubectl -n kube-system get deployment aws-load-balancer-controller
```

## Step E — Build and push the app image
### Option 1 (local build)
```bash
cd ../../app
./scripts/push_to_ecr.sh \
  --region $(terraform -chdir=../iac/terraform output -raw region) \
  --ecr $(terraform -chdir=../iac/terraform output -raw ecr_repository_url) \
  --tag v1
```

### Option 2 (CI/CD)
Push to GitHub and run the **App pipeline** workflow.

## Step F — Deploy Kubernetes manifests
```bash
cd ../k8s/overlays/dev
./deploy.sh \
  --image "$(terraform -chdir=../../iac/terraform output -raw ecr_repository_url):v1" \
  --mongo_ip "$(terraform -chdir=../../iac/terraform output -raw mongo_private_ip)" \
  --mongo_user "wizuser" \
  --mongo_pass "wizpass"
```

## Step G — Validate the web app and DB
Get Ingress hostname:
```bash
kubectl -n wiz get ingress wizapp -o jsonpath='{{.status.loadBalancer.ingress[0].hostname}}'; echo
```

Open it in a browser and create an item. Then validate DB has data:
```bash
kubectl -n wiz logs deploy/wizapp --tail=100
```

---

# 3) Required Demo Proof Points (Commands)

## Prove `wizexercise.txt` exists in the running container
```bash
POD=$(kubectl -n wiz get pod -l app=wizapp -o jsonpath='{{.items[0].metadata.name}}')
kubectl -n wiz exec -it $POD -- cat /wizexercise.txt
```

## Prove the application has cluster-admin
```bash
kubectl auth can-i '*' '*' --as=system:serviceaccount:wiz:wizapp-sa
```

## Prove data is in MongoDB
Exec into MongoDB from a debug pod in cluster:
```bash
kubectl -n wiz run mongo-client --rm -it --image=mongo:5.0 -- \
  mongosh "mongodb://wizuser:wizpass@$(terraform -chdir=../iac/terraform output -raw mongo_private_ip):27017/wizdb?authSource=admin" \
  --eval "db.items.find().limit(5).toArray()"
```

## Prove backups are in public S3 (intentional risk)
```bash
aws s3 ls s3://$(terraform -chdir=../iac/terraform output -raw s3_backup_bucket_name) --no-sign-request
```

---

# 4) Cleanup
```bash
cd iac/terraform
terraform destroy -auto-approve
```

---

# 5) Submission Checklist
Use `docs/submission-checklist.md` to ensure you have:
- IaC deploy success + diagram + decisions
- App live URL + demo steps + kubectl proof
- Misconfigurations explained + blast radius
- Cloud native controls shown
- CI/CD security controls shown
- Screenshots for backup/public bucket and Wiz findings
>>>>>>> 14236b4 (wiz-exercise)
