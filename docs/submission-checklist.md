# Submission Checklist

## Artifacts to provide
- Repo URL (GitHub/GitLab) with:
  - IaC (Terraform)
  - App source + Dockerfile
  - K8s manifests
  - CI/CD workflows
  - Docs

## Screenshots / Proof
- Terraform apply success (outputs visible)
- EKS nodes ready
- Ingress hostname + app working in browser
- `cat /wizexercise.txt` from running container
- MongoDB query from inside cluster (mongosh)
- Public S3 listing of backups (`--no-sign-request`)
- CloudTrail + GuardDuty enabled
- Wiz dashboard showing findings (if applicable)

## Live demo flow
- kubectl usage
- app functionality
- DB persistence
- risks + remediation discussion
