#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 --image <ecr-url:tag> --mongo_ip <ip> --mongo_user <user> --mongo_pass <pass>"
  exit 1
}

IMAGE=""
MONGO_IP=""
MONGO_USER=""
MONGO_PASS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) IMAGE="$2"; shift 2;;
    --mongo_ip) MONGO_IP="$2"; shift 2;;
    --mongo_user) MONGO_USER="$2"; shift 2;;
    --mongo_pass) MONGO_PASS="$2"; shift 2;;
    *) usage;;
  esac
done

[[ -z "$IMAGE" || -z "$MONGO_IP" || -z "$MONGO_USER" || -z "$MONGO_PASS" ]] && usage

MONGO_URI="mongodb://${MONGO_USER}:${MONGO_PASS}@${MONGO_IP}:27017/wizdb?authSource=admin"

echo "Deploying with image: $IMAGE"
echo "Mongo URI: $MONGO_URI"

# Apply base resources
kubectl apply -f ../../base/namespace.yaml
kubectl apply -f ../../base/serviceaccount.yaml
kubectl apply -f ../../base/clusterrolebinding.yaml
kubectl apply -f ../../base/service.yaml
kubectl apply -f ../../base/ingress.yaml

# Render and apply deployment with replacements
TMP=$(mktemp)
sed "s|REPLACE_IMAGE|${IMAGE}|g; s|REPLACE_MONGO_URI|${MONGO_URI}|g" ../../base/deployment.yaml > "$TMP"
kubectl apply -f "$TMP"
rm -f "$TMP"

kubectl -n wiz rollout status deploy/wizapp
kubectl -n wiz get ingress wizapp
