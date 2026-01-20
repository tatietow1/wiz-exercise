locals {
  name = var.project_name
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
}

# -----------------------------
# VPC
# -----------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.3"

  name = local.name
  cidr = "10.0.0.0/16"

  azs             = local.azs
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Project = local.name
  }
}

# EKS cluster auth for providers
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

# -----------------------------
# EKS
# - Cluster in private subnets
# - Private endpoint enabled (preventive control)
# - Control plane logs enabled (audit logging requirement)
# -----------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = "${local.name}-eks"
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  eks_managed_node_groups = {
    default = {
      name           = "${local.name}-ng"
      instance_types = var.node_instance_types
      desired_size   = 2
      min_size       = 2
      max_size       = 3
      subnet_ids     = module.vpc.private_subnets
    }
  }

  tags = {
    Project = local.name
  }
}

# -----------------------------
# ECR repo for the app image
# -----------------------------
resource "aws_ecr_repository" "wizapp" {
  name                 = "${local.name}-wizapp"
  image_tag_mutability = "MUTABLE"
}

# -----------------------------
# S3 bucket for MongoDB backups
# Intentional weakness: public list + public read
# -----------------------------
resource "aws_s3_bucket" "mongo_backups" {
  bucket        = "${local.name}-mongo-backups-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "mongo_backups" {
  bucket = aws_s3_bucket.mongo_backups.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "mongo_backups_public" {
  bucket = aws_s3_bucket.mongo_backups.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicListBucket",
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:ListBucket"],
        Resource  = aws_s3_bucket.mongo_backups.arn
      },
      {
        Sid       = "PublicReadObjects",
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject"],
        Resource  = "${aws_s3_bucket.mongo_backups.arn}/*"
      }
    ]
  })
}

# -----------------------------
# IAM role for Mongo VM (EC2)
# - Overly permissive EC2 permissions (intentional weakness)
# - S3 put for backups
# -----------------------------
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mongo_vm" {
  name               = "${local.name}-mongo-vm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy" "mongo_vm_over_permissive" {
  name = "${local.name}-mongo-vm-over-permissive"
  role = aws_iam_role.mongo_vm.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Intentional: overly permissive EC2 permissions
      {
        Effect   = "Allow",
        Action   = ["ec2:*"],
        Resource = "*"
      },
      # Needed for backups
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject", "s3:PutObjectAcl", "s3:ListBucket"],
        Resource = [aws_s3_bucket.mongo_backups.arn, "${aws_s3_bucket.mongo_backups.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "mongo_vm" {
  name = "${local.name}-mongo-vm-profile"
  role = aws_iam_role.mongo_vm.name
}

# -----------------------------
# Mongo VM Security Group
# - SSH exposed to public internet (exercise requirement)
# - MongoDB 27017 restricted to EKS node SG (k8s network only)
# -----------------------------
resource "aws_security_group" "mongo_vm" {
  name        = "${local.name}-mongo-sg"
  description = "Mongo VM SG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH (public)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # MongoDB restricted to EKS node security group only
  ingress {
    description              = "MongoDB from EKS nodes only"
    from_port                = 27017
    to_port                  = 27017
    protocol                 = "tcp"
    source_security_group_id = module.eks.node_security_group_id
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = local.name
  }
}

# -----------------------------
# Ubuntu 20.04 AMI (older release; satisfies "1+ year outdated OS" intent)
# -----------------------------
data "aws_ami" "ubuntu_2004" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------
# Mongo EC2 instance (public subnet for SSH access)
# - MongoDB 5.0 + auth enabled
# - Daily backup to public S3 bucket
# -----------------------------
resource "aws_instance" "mongo" {
  ami                         = data.aws_ami.ubuntu_2004.id
  instance_type               = "t3.small"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.mongo_vm.id]
  iam_instance_profile        = aws_iam_instance_profile.mongo_vm.name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data_mongo.sh.tftpl", {
    mongo_admin_user = var.mongo_admin_user
    mongo_admin_pass = var.mongo_admin_pass
    s3_bucket_name   = aws_s3_bucket.mongo_backups.bucket
    region           = var.region
  })

  tags = {
    Name    = "${local.name}-mongo"
    Project = local.name
  }
}

# -----------------------------
# CloudTrail (detective control)
# -----------------------------
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${local.name}-cloudtrail-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_cloudtrail" "main" {
  name                          = "${local.name}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
}

# -----------------------------
# GuardDuty (detective control)
# -----------------------------
resource "aws_guardduty_detector" "main" {
  enable = true
}

# -----------------------------
# AWS Load Balancer Controller (Helm)
# -----------------------------
resource "aws_iam_policy" "alb_controller" {
  name        = "${local.name}-alb-controller-policy"
  description = "Policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/policies/alb-controller-iam-policy.json")
}

module "alb_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.39.1"

  role_name = "${local.name}-alb-controller-irsa"

  attach_policy_arns = [aws_iam_policy.alb_controller.arn]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.2"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\.amazonaws\.com/role-arn"
    value = module.alb_irsa.iam_role_arn
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  depends_on = [module.eks]
}
