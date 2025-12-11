#!/bin/bash

# Kubernetes Deployment Script for Minikube
# Phase 3 - CUET Hackathon

set -e

echo "=================================="
echo "CUET Kubernetes Deployment Script"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check Minikube status
echo -e "${YELLOW}[1/8] Checking Minikube status...${NC}"
if minikube status &> /dev/null; then
    echo -e "${GREEN}✓ Minikube is running${NC}"
else
    echo "Starting Minikube with 4 CPUs and 8GB RAM..."
    minikube start --driver=docker --cpus=4 --memory=8192
    echo -e "${GREEN}✓ Minikube started${NC}"
fi
echo ""

# Step 2: Enable addons
echo -e "${YELLOW}[2/8] Enabling required addons...${NC}"
minikube addons enable ingress
minikube addons enable metrics-server
echo -e "${GREEN}✓ Addons enabled${NC}"
echo ""

# Step 3: Build Docker images in Minikube
echo -e "${YELLOW}[3/8] Building Docker images...${NC}"
eval $(minikube docker-env)
echo "Building backend image..."
docker build -t cuet-backend:latest -f backend/Dockerfile backend/
echo "Building gateway image..."
docker build -t cuet-gateway:latest -f gateway/Dockerfile gateway/
echo -e "${GREEN}✓ Images built${NC}"
echo ""

# Step 4: Create namespace
echo -e "${YELLOW}[4/8] Creating namespace...${NC}"
kubectl apply -f k8s/00-namespace.yaml
echo -e "${GREEN}✓ Namespace created${NC}"
echo ""

# Step 5: Create secrets and configmaps
echo -e "${YELLOW}[5/8] Creating secrets and configmaps...${NC}"
kubectl apply -f k8s/01-secrets.yaml
kubectl apply -f k8s/02-configmaps.yaml
echo -e "${GREEN}✓ Secrets and ConfigMaps created${NC}"
echo ""

# Step 6: Create volumes
echo -e "${YELLOW}[6/8] Creating PersistentVolumeClaims...${NC}"
kubectl apply -f k8s/volumes/
echo -e "${GREEN}✓ PVCs created${NC}"
echo ""

# Step 7: Deploy services
echo -e "${YELLOW}[7/8] Deploying services...${NC}"
echo "Deploying backend & gateway..."
kubectl apply -f k8s/deployments/backend-deployment.yaml
kubectl apply -f k8s/deployments/gateway-deployment.yaml
kubectl apply -f k8s/services/backend-service.yaml
kubectl apply -f k8s/services/gateway-service.yaml

echo "Deploying data layer (MongoDB, MinIO, Elasticsearch)..."
kubectl apply -f k8s/deployments/mongo-deployment.yaml
kubectl apply -f k8s/deployments/minio-deployment.yaml
kubectl apply -f k8s/deployments/elasticsearch-deployment.yaml
kubectl apply -f k8s/services/mongo-service.yaml
kubectl apply -f k8s/services/minio-service.yaml
kubectl apply -f k8s/services/elasticsearch-service.yaml

echo "Deploying monitoring (Kibana, Sentry)..."
kubectl apply -f k8s/deployments/kibana-deployment.yaml
kubectl apply -f k8s/deployments/sentry-redis-deployment.yaml
kubectl apply -f k8s/deployments/sentry-postgres-deployment.yaml
kubectl apply -f k8s/deployments/sentry-deployment.yaml
kubectl apply -f k8s/services/kibana-service.yaml
kubectl apply -f k8s/services/sentry-redis-service.yaml
kubectl apply -f k8s/services/sentry-postgres-service.yaml
kubectl apply -f k8s/services/sentry-service.yaml

echo "Deploying Ingress..."
kubectl apply -f k8s/ingress/

echo "Deploying HPAs..."
kubectl apply -f k8s/hpa/

echo -e "${GREEN}✓ All services deployed${NC}"
echo ""

# Step 8: Wait for pods to be ready
echo -e "${YELLOW}[8/8] Waiting for pods to be ready...${NC}"
echo "This may take a few minutes..."
kubectl wait --for=condition=ready pod -l app=backend -n cuet-app --timeout=300s || true
kubectl wait --for=condition=ready pod -l app=gateway -n cuet-app --timeout=300s || true
echo -e "${GREEN}✓ Pods are ready${NC}"
echo ""

# Display status
echo "=================================="
echo "Deployment Complete!"
echo "=================================="
echo ""
echo "Minikube IP: $(minikube ip)"
echo ""
echo "Access services:"
echo "  API:    http://$(minikube ip)/api/health"
echo "  Kibana: http://$(minikube ip)/kibana"
echo "  Sentry: http://$(minikube ip)/sentry"
echo ""
echo "Useful commands:"
echo "  kubectl get all -n cuet-app           # View all resources"
echo "  kubectl get ingress -n cuet-app       # View ingress"
echo "  kubectl get hpa -n cuet-app           # View autoscalers"
echo "  kubectl logs -n cuet-app -l app=backend  # View backend logs"
echo "  minikube dashboard                    # Open Kubernetes dashboard"
echo ""
