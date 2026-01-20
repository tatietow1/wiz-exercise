#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 --region <aws-region> --ecr <ecr-repo-url> --tag <tag>"
  exit 1
}

REGION=""
ECR=""
TAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region) REGION="$2"; shift 2;;
    --ecr) ECR="$2"; shift 2;;
    --tag) TAG="$2"; shift 2;;
    *) usage;;
  esac
done

[[ -z "$REGION" || -z "$ECR" || -z "$TAG" ]] && usage

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

docker build -t wizapp:"$TAG" .
docker tag wizapp:"$TAG" "$ECR":"$TAG"
docker push "$ECR":"$TAG"

echo "Pushed: $ECR:$TAG"
