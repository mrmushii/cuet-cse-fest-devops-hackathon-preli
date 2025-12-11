#!/bin/bash

# Deployment Script for Minikube VM
# Executed via SSH from GitHub Actions CD workflow

set -e

NAMESPACE="cuet-app"
BACKEND_IMAGE="cuet-backend:latest"
GATEWAY_IMAGE="cuet-gateway:latest"

echo "========================================="
echo "Kubernetes Deployment Script"
echo "========================================="
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Validate prerequisites
echo "[1/6] Validating prerequisites..."
if ! command_exists kubectl; then
    echo "Error: kubectl not found"
    exit 1
fi

if ! command_exists minikube; then
    echo "Error: minikube not found"
    exit 1
fi

if ! minikube status > /dev/null 2>&1; then
    echo "Error: Minikube is not running"
    exit 1
fi

echo "✓ Prerequisites validated"
echo ""

# Set Docker environment to Minikube
echo "[2/6] Configuring Docker environment..."
eval $(minikube docker-env)
echo "✓ Docker environment configured"
echo ""

# Pull and tag images
echo "[3/6] Pulling images from GHCR..."
docker pull ghcr.io/${GITHUB_REPOSITORY}/backend:latest
docker pull ghcr.io/${GITHUB_REPOSITORY}/gateway:latest

echo "Tagging images for Minikube..."
docker tag ghcr.io/${GITHUB_REPOSITORY}/backend:latest ${BACKEND_IMAGE}
docker tag ghcr.io/${GITHUB_REPOSITORY}/gateway:latest ${GATEWAY_IMAGE}
echo "✓ Images pulled and tagged"
echo ""

# Apply Kubernetes manifests
echo "[4/6] Applying Kubernetes manifests..."
K8S_DIR="${HOME}/k8s"

if [ ! -d "$K8S_DIR" ]; then
    echo "Error: K8s directory not found at $K8S_DIR"
    exit 1
fi

kubectl apply -f ${K8S_DIR}/00-namespace.yaml
kubectl apply -f ${K8S_DIR}/01-secrets.yaml
kubectl apply -f ${K8S_DIR}/02-configmaps.yaml
kubectl apply -f ${K8S_DIR}/volumes/
kubectl apply -f ${K8S_DIR}/deployments/
kubectl apply -f ${K8S_DIR}/services/
kubectl apply -f ${K8S_DIR}/ingress/
kubectl apply -f ${K8S_DIR}/hpa/

echo "✓ Manifests applied"
echo ""

# Restart deployments to pull new images
echo "[5/6] Restarting deployments..."
kubectl rollout restart deployment/backend -n ${NAMESPACE}
kubectl rollout restart deployment/gateway -n ${NAMESPACE}
echo "✓ Deployments restarted"
echo ""

# Wait for rollout
echo "[6/6] Waiting for rollout to complete..."
kubectl rollout status deployment/backend -n ${NAMESPACE} --timeout=5m
kubectl rollout status deployment/gateway -n ${NAMESPACE} --timeout=5m
echo "✓ Rollout completed"
echo ""

echo "========================================="
echo "Deployment Successful!"
echo "========================================="
echo ""
echo "Current status:"
kubectl get pods -n ${NAMESPACE}
echo ""
kubectl get deployments -n ${NAMESPACE}
echo ""
echo "HPA status:"
kubectl get hpa -n ${NAMESPACE}
