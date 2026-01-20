# GitHub Actions OIDC for AWS (Recommended)

This repo includes workflows that can use GitHub OIDC so you do not store long-lived AWS keys.

## 1) Create IAM OIDC provider in AWS
AWS console: IAM → Identity providers → Add provider → OpenID Connect
- Provider URL: https://token.actions.githubusercontent.com
- Audience: sts.amazonaws.com

## 2) Create IAM role for GitHub Actions
Create a role with:
- Trusted entity: Web identity
- Principal: token.actions.githubusercontent.com
- Condition: restrict to your repo and branch

Attach policies for:
- Terraform deploy workflow: VPC/EKS/EC2/S3/ECR/IAM as needed
- ECR push + EKS deploy: ecr:*, eks:DescribeCluster, sts:AssumeRoleWithWebIdentity, plus kubectl access mapped in aws-auth (handled by EKS module)

## 3) Update workflow variables
In `.github/workflows/*.yml`, set:
- AWS_REGION
- AWS_ROLE_ARN

## 4) Run workflows
- IaC: deploy infra
- App: build/push container and deploy to EKS
