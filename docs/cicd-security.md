# CI/CD Security Controls Implemented

## Repository controls (configure in GitHub)
- Branch protection on main
- Require PR reviews
- Require status checks (tfsec + trivy)
- Enable secret scanning
- Enable Dependabot alerts

## Pipeline scanning in workflows
- **tfsec** scans Terraform before deploy
- **Trivy** scans the container image before push/deploy

## Credentials best practice
- GitHub Actions uses AWS **OIDC** (short-lived credentials)
- Avoid long-lived AWS access keys in repo secrets
