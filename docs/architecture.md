# Architecture

## Components
1. **VPC**
   - Public subnets: ALB, EC2 Mongo host (SSH open)
   - Private subnets: EKS control plane access + nodes

2. **EKS**
   - Private endpoint enabled (preventive control)
   - Control plane logging enabled (audit, api, authenticator, controllerManager, scheduler)

3. **MongoDB (EC2)**
   - Ubuntu 20.04 (older release)
   - MongoDB 5.0 (older release)
   - SSH open to public internet (intentional weakness)
   - IAM role intentionally over-permissive (ec2:*), plus S3 put for backups

4. **S3**
   - Backup bucket is **publicly listable** and **publicly readable** (intentional weakness)
   - Daily backups from Mongo VM

5. **Ingress**
   - AWS Load Balancer Controller provisions public ALB for Kubernetes Ingress

## Key Intentional Misconfigurations
- EC2 SSH (22) open to 0.0.0.0/0 (or your chosen CIDR)
- EC2 IAM role with overly permissive EC2 permissions
- S3 backups bucket: public list + public read
- Kubernetes app ServiceAccount bound to cluster-admin
