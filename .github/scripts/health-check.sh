#!/bin/bash

# Health Check Script for Post-Deployment Verification
# Tests all critical endpoints and services

set -e

NAMESPACE="cuet-app"
TIMEOUT=30
FAILED=0

echo "========================================="
echo "Running Health Checks"
echo "========================================="
echo ""

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: ${MINIKUBE_IP}"
echo ""

# Function to check HTTP endpoint
check_endpoint() {
    local url=$1
    local description=$2
    local expected_code=${3:-200}
    
    echo -n "Checking ${description}... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time ${TIMEOUT} ${url} || echo "000")
    
    if [ "$response" = "$expected_code" ]; then
        echo "✓ (${response})"
        return 0
    else
        echo "✗ (${response}, expected ${expected_code})"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Function to check pod status
check_pods() {
    local app=$1
    echo -n "Checking ${app} pods... "
    
    ready=$(kubectl get pods -n ${NAMESPACE} -l app=${app} -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -o "True" | wc -l)
    total=$(kubectl get pods -n ${NAMESPACE} -l app=${app} --no-headers | wc -l)
    
    if [ "$ready" -eq "$total" ] && [ "$total" -gt 0 ]; then
        echo "✓ (${ready}/${total} ready)"
        return 0
    else
        echo "✗ (${ready}/${total} ready)"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# 1. Check Pod Status
echo "[1/4] Checking Pod Status"
echo "-------------------------"
check_pods "backend"
check_pods "gateway"
check_pods "mongodb"
check_pods "elasticsearch"
check_pods "kibana"
echo ""

# 2. Check Core Endpoints
echo "[2/4] Checking Core Endpoints"
echo "-----------------------------"
check_endpoint "http://${MINIKUBE_IP}/api/health" "Backend API (via Ingress)"
check_endpoint "http://${MINIKUBE_IP}/health" "Gateway Health" 404  # Gateway doesn't have /health without /api
echo ""

# 3. Check Monitoring Services
echo "[3/4] Checking Monitoring Services"
echo "-----------------------------------"
check_endpoint "http://${MINIKUBE_IP}/kibana/api/status" "Kibana" || true  # May not be ready yet
echo ""

# 4. Check HPA Status
echo "[4/4] Checking HPA Status"
echo "-------------------------"
hpa_count=$(kubectl get hpa -n ${NAMESPACE} --no-headers | wc -l)
if [ "$hpa_count" -ge 2 ]; then
    echo "✓ HPAs configured (${hpa_count} active)"
else
    echo "✗ HPAs not configured properly"
    FAILED=$((FAILED + 1))
fi
echo ""

# Summary
echo "========================================="
if [ $FAILED -eq 0 ]; then
    echo "All Health Checks Passed! ✓"
    echo "========================================="
    exit 0
else
    echo "Health Checks Failed: ${FAILED} failures"
    echo "========================================="
    echo ""
    echo "Pod status:"
    kubectl get pods -n ${NAMESPACE}
    echo ""
    echo "Recent events:"
    kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp' | tail -10
    exit 1
fi
