# Demo Guide (Suggested 45 minutes)

## 1) Infrastructure proof (Terraform outputs)
- Show `terraform apply` output (or saved screenshot)
- Show key outputs:
  - EKS cluster name
  - Mongo private IP
  - S3 bucket name
  - ECR repo URL

## 2) Kubernetes proof (kubectl)
- `kubectl get nodes`
- `kubectl -n kube-system get deploy aws-load-balancer-controller`
- `kubectl -n wiz get all`
- Show Ingress hostname and open app in browser

## 3) Web application functionality
- Create items in UI
- Refresh and show persisted data

## 4) DB proof
- Run mongosh from inside cluster to show items are stored in MongoDB

## 5) Required file proof
- `kubectl exec` and show `/wizexercise.txt` contains your name

## 6) RBAC misconfiguration proof
- `kubectl auth can-i '*' '*' --as=system:serviceaccount:wiz:wizapp-sa`

## 7) Backup proof
- `aws s3 ls s3://<bucket> --no-sign-request`
- Explain the risk of public list/read

## 8) Cloud-native security controls
- CloudTrail enabled and collecting
- GuardDuty enabled and producing findings (if triggered)
- EKS control plane logs configured

## 9) Wiz value (if asked)
- Show how Wiz identifies: public bucket, over-privileged IAM, outdated VM, risky K8s RBAC, public ingress exposure
- Show prioritized risk and remediation guidance
