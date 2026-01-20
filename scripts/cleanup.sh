#!/usr/bin/env bash
set -euo pipefail

cd iac/terraform
terraform destroy -auto-approve
