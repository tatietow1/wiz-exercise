output "region" {
  value = var.region
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "mongo_private_ip" {
  value = aws_instance.mongo.private_ip
}

output "mongo_public_ip" {
  value = aws_instance.mongo.public_ip
}

output "s3_backup_bucket_name" {
  value = aws_s3_bucket.mongo_backups.bucket
}

output "ecr_repository_url" {
  value = aws_ecr_repository.wizapp.repository_url
}
