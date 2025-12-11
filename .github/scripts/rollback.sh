#!/bin/bash

# Rollback Script for Kubernetes Deployments
# Reverts deployments to previous stable version

set -e

NAMESPACE="cuet-app"
SERVICE="${1:-all}"
REVISION="${2:-}"

echo "========================================="
echo "Kubernetes Rollback Script"
echo "========================================="
echo ""

# Function to rollback a service
rollback_service() {
    local svc=$1
    local revision=$2
    
    echo "Rolling back ${svc}..."
    
    # Check if deployment exists
    if ! kubectl get deployment/${svc} -n ${NAMESPACE} > /dev/null 2>&1; then
        echo "Error: Deployment ${svc} not found"
        return 1
    fi
    
    # Show current revision history
    echo "Current revision history:"
    kubectl rollout history deployment/${svc} -n ${NAMESPACE}
    echo ""
    
    # Perform rollback
    if [ -n "$revision" ]; then
        echo "Rolling back to revision ${revision}..."
        kubectl rollout undo deployment/${svc} -n ${NAMESPACE} --to-revision=${revision}
    else
        echo "Rolling back to previous revision..."
        kubectl rollout undo deployment/${svc} -n ${NAMESPACE}
    fi
    
    # Wait for rollback to complete
    echo "Waiting for rollback to complete..."
    kubectl rollout status deployment/${svc} -n ${NAMESPACE} --timeout=5m
    
    echo "✓ ${svc} rolled back successfully"
    echo ""
}

# Validate namespace exists
if ! kubectl get namespace ${NAMESPACE} > /dev/null 2>&1; then
    echo "Error: Namespace ${NAMESPACE} not found"
    exit 1
fi

# Perform rollback
if [ "$SERVICE" = "all" ]; then
    echo "Rolling back all services..."
    rollback_service "backend" "$REVISION"
    rollback_service "gateway" "$REVISION"
else
    rollback_service "$SERVICE" "$REVISION"
fi

# Show final status
echo "========================================="
echo "Rollback Complete!"
echo "========================================="
echo ""
echo "Current pod status:"
kubectl get pods -n ${NAMESPACE}
echo ""
echo "Deployment status:"
kubectl get deployments -n ${NAMESPACE}
echo ""

# Test health
echo "Testing API health..."
MINIKUBE_IP=$(minikube ip)
if curl -f -s http://${MINIKUBE_IP}/api/health > /dev/null; then
    echo "✓ API health check passed"
else
    echo "✗ API health check failed"
    exit 1
fi
