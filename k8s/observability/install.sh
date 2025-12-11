#!/bin/bash

# Observability Stack Installation Script

set -e

echo "========================================="
echo "Installing Observability Stack"
echo "========================================="
echo ""

# Step 1: Add Helm repositories
echo "[1/5] Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
echo "✓ Helm repos updated"
echo ""

# Step 2: Install Prometheus Stack
echo "[2/5] Installing kube-prometheus-stack..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f k8s/observability/prometheus-values.yaml \
  --wait
echo "✓ Prometheus stack installed"
echo ""

# Step 3: Deploy ServiceMonitors
echo "[3/5] Deploying ServiceMonitors..."
kubectl apply -f k8s/observability/servicemonitor-backend.yaml
kubectl apply -f k8s/observability/servicemonitor-gateway.yaml
kubectl apply -f k8s/observability/servicemonitor-nginx.yaml
echo "✓ ServiceMonitors deployed"
echo ""

# Step 4: Deploy Fluentd
echo "[4/5] Deploying Fluentd for log aggregation..."
kubectl apply -f k8s/observability/fluentd-configmap.yaml
kubectl apply -f k8s/observability/fluentd-daemonset.yaml
echo "✓ Fluentd deployed"
echo ""

# Step 5: Apply alert rules
echo "[5/5] Applying Prometheus alert rules..."
kubectl apply -f k8s/observability/alerts/prometheus-rules.yaml
echo "✓ Alert rules applied"
echo ""

echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo ""
echo "Access Grafana:"
echo "  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "  Username: admin"
echo "  Password: admin"
echo ""
echo "Access Prometheus:"
echo "  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo ""
echo "Import Dashboards:"
echo "  Grafana → + → Import → Upload JSON files from k8s/observability/dashboards/"
echo ""
echo "Check ServiceMonitor targets:"
echo "  Prometheus → Status → Targets"
echo ""
