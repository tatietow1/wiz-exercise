variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "wiz-exercise"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH to Mongo VM (exercise says public; still set something reasonable for demo)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "mongo_admin_user" {
  type        = string
  default     = "wizuser"
}

variable "mongo_admin_pass" {
  type        = string
  default     = "wizpass"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.29"
}

variable "node_instance_types" {
  type        = list(string)
  default     = ["t3.large"]
}
