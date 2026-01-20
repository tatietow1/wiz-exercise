# Weak Configurations, Consequences, and Remediations

## 1) Public SSH to Mongo VM
**Risk:** brute force, credential stuffing, exploit of OS services  
**Impact:** host compromise -> credential theft -> lateral movement  
**Fix:** restrict SSH to VPN/bastion, use SSM Session Manager, enforce MFA and short-lived credentials

## 2) Over-permissive EC2 IAM Role (ec2:*)
**Risk:** attacker on VM can create/modify instances, exfiltrate snapshots, persist  
**Impact:** cloud account takeover patterns, resource abuse, ransomware staging  
**Fix:** least privilege; isolate backup permissions to only required S3 actions; use permission boundaries

## 3) Public S3 bucket (list + read) for backups
**Risk:** complete DB backup disclosure; sensitive data exposure  
**Impact:** data breach + compliance impact; credential reuse if stored  
**Fix:** block public access, encrypt objects, use private bucket policy; use presigned URLs if needed

## 4) Cluster-admin ServiceAccount for application pod
**Risk:** container compromise becomes cluster compromise  
**Impact:** secret theft, workload takeover, persistence, node access  
**Fix:** least privilege RBAC; namespace-scoped roles; pod security controls; admission policies

## 5) Outdated OS and MongoDB version
**Risk:** known CVEs; exploit chains easier  
**Impact:** remote code execution, privilege escalation  
**Fix:** patch management; use managed DB (DocumentDB) or hardened AMIs; continuous scanning
