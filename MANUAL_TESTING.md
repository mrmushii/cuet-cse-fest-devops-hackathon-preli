# Manual Testing & Verification Guide

Complete step-by-step guide to test all components of your DevOps setup.

---

## Prerequisites

```bash
# Ensure you have these installed
minikube version
kubectl version --client
docker --version
helm version
```

---

## Phase 1: Docker Testing (Local)

### Start Docker Compose (Development)

```bash
# Navigate to project root
cd d:\devops\cuet-cse-fest-devops-hackathon-preli

# Start all services
docker-compose -f docker/compose.development.yaml up -d

# Check all services are running
docker-compose -f docker/compose.development.yaml ps

# Should see:
# backend, gateway, mongo, nginx, minio, elasticsearch, kibana, sentry, sentry-redis, sentry-postgres
```

### Test Endpoints

```bash
# Test NGINX (main entry point)
curl http://localhost/health

# Test Backend via NGINX
curl http://localhost/api/health

# Test Gateway directly
curl http://localhost:5921/health
```

### Access Docker Services

| Service | URL | Credentials |
|---------|-----|-------------|
| NGINX | http://localhost | - |
| Backend API | http://localhost/api/health | - |
| MinIO Console | http://localhost:9001 | minioadmin/minioadmin |
| Kibana | http://localhost/kibana | - |
| Sentry | http://localhost:9002 | Setup on first visit |
| MongoDB | localhost:27017 | From .env |

### Stop Docker Compose

```bash
docker-compose -f docker/compose.development.yaml down
```

---

## Phase 2: Kubernetes Testing (Minikube)

### Start Minikube

```bash
# Start Minikube with enough resources
minikube start --driver=docker --cpus=4 --memory=8192

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
```

### Deploy Application to Kubernetes

```bash
# Navigate to k8s directory
cd k8s

# Run the setup script
bash setup.sh

# OR manually apply:
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-secrets.yaml
kubectl apply -f 02-configmaps.yaml
kubectl apply -f volumes/
kubectl apply -f deployments/
kubectl apply -f services/
kubectl apply -f ingress/
kubectl apply -f hpa/
```

### Verify Deployments

```bash
# Check all resources in cuet-app namespace
kubectl get all -n cuet-app

# Check pods are running
kubectl get pods -n cuet-app

# Should see pods for:
# - backend (2 replicas)
# - gateway (2 replicas)
# - mongodb
# - minio
# - elasticsearch
# - kibana
# - sentry
# - sentry-redis
# - sentry-postgres

# Check pod details
kubectl describe pod <pod-name> -n cuet-app

# Check logs
kubectl logs -n cuet-app -l app=backend --tail=50
kubectl logs -n cuet-app -l app=gateway --tail=50
```

### Test Ingress

```bash
# Get Minikube IP
minikube ip
# Example output: 192.168.49.2

# Test endpoints (replace with your minikube IP)
curl http://192.168.49.2/api/health
curl http://192.168.49.2/kibana
```

### Check HPAs

```bash
# View Horizontal Pod Autoscalers
kubectl get hpa -n cuet-app

# Should show:
# backend-hpa    Deployment/backend    <CPU>/70%    2    5    2
# gateway-hpa    Deployment/gateway    <CPU>/70%    2    4    2

# Watch HPA in real-time
kubectl get hpa -n cuet-app --watch
```

---

## Phase 3: Observability Stack

### Install Prometheus Stack

```bash
# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
cd k8s/observability
bash install.sh

# OR manually:
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f prometheus-values.yaml
```

### Verify Prometheus Installation

```bash
# Check monitoring namespace
kubectl get all -n monitoring

# Should see:
# - prometheus pods
# - grafana pods
# - alertmanager pods
# - operator pods
```

### Access Grafana

```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Open browser: http://localhost:3000
# Username: admin
# Password: admin (will be prompted to change)
```

**In Grafana UI:**
1. Go to **Configuration** → **Data Sources**
2. Verify Prometheus is configured
3. Go to **Dashboards** → **Browse**
4. Click **Import** → **Upload JSON file**
5. Import dashboards from `k8s/observability/dashboards/`:
   - cluster-overview.json
   - application-performance.json
   - pod-resources.json
   - nginx-ingress.json

### Access Prometheus

```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Open browser: http://localhost:9090
```

**In Prometheus UI:**
1. Go to **Status** → **Targets**
2. Verify ServiceMonitors are discovered
3. Check targets are UP (backend, gateway, nginx)
4. Go to **Graph** tab and try queries:
   ```promql
   # Total pods
   count(kube_pod_info{namespace="cuet-app"})
   
   # CPU usage
   sum(rate(container_cpu_usage_seconds_total{namespace="cuet-app"}[5m])) by (pod)
   
   # Memory usage
   sum(container_memory_working_set_bytes{namespace="cuet-app"}) by (pod)
   ```

### Access AlertManager

```bash
# Port-forward AlertManager
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093

# Open browser: http://localhost:9093
```

**Check Alerts:**
- Should see any active/pending alerts
- Can silence alerts from UI
- Configure notification receivers (Slack, Email)

---

## Phase 4: Logs & Kibana

### Verify Fluentd

```bash
# Check Fluentd DaemonSet
kubectl get daemonset -n kube-system -l app=fluentd

# Check logs
kubectl logs -n kube-system -l app=fluentd --tail=50

# Should see log forwarding messages
```

### Access Kibana

```bash
# Via Ingress (if Minikube)
minikube ip
# Browser: http://<minikube-ip>/kibana

# OR Port-forward
kubectl port-forward -n cuet-app svc/kibana-service 5601:5601
# Browser: http://localhost:5601
```

**In Kibana:**
1. Go to **Management** → **Stack Management**
2. Click **Index Patterns**
3. Create index pattern: `kubernetes-*`
4. Set time field: `@timestamp`
5. Go to **Discover** to view logs
6. Filter by namespace: `kubernetes.namespace_name: cuet-app`

---

## Phase 5: Service-Specific Checks

### MongoDB

```bash
# Port-forward MongoDB
kubectl port-forward -n cuet-app svc/mongodb-service 27017:27017

# Connect with mongosh
mongosh mongodb://admin:changeme123@localhost:27017/cuet_db --authenticationDatabase admin

# Or use MongoDB Compass GUI
# Connection string: mongodb://admin:changeme123@localhost:27017/cuet_db?authSource=admin
```

### MinIO

```bash
# Port-forward MinIO console
kubectl port-forward -n cuet-app svc/minio-service 9001:9001

# Browser: http://localhost:9001
# Username: minioadmin
# Password: minioadmin

# Create a bucket, upload a file to test
```

### Elasticsearch

```bash
# Port-forward Elasticsearch
kubectl port-forward -n cuet-app svc/elasticsearch-service 9200:9200

# Test cluster health
curl http://localhost:9200/_cluster/health

# List indices
curl http://localhost:9200/_cat/indices?v
```

### Sentry

```bash
# Port-forward Sentry
kubectl port-forward -n cuet-app svc/sentry-service 9000:9000

# Browser: http://localhost:9000
# First-time setup wizard will appear
```

---

## Phase 6: Scaling & Auto-scaling Tests

### Manual Scaling

```bash
# Scale backend deployment
kubectl scale deployment/backend -n cuet-app --replicas=4

# Watch pods being created
kubectl get pods -n cuet-app -w

# Scale back down
kubectl scale deployment/backend -n cuet-app --replicas=2
```

### Test HPA (Autoscaling)

```bash
# Generate load
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh

# Inside the pod, run:
while true; do wget -q -O- http://backend-service.cuet-app.svc.cluster.local:3847/api/health; done

# In another terminal, watch HPA
kubectl get hpa -n cuet-app --watch

# Should see CPU increase and replicas scale up
```

---

## Phase 7: Rollout & Rollback

### Update Deployment (Simulate)

```bash
# Update image tag
kubectl set image deployment/backend backend=cuet-backend:v2 -n cuet-app

# Watch rollout
kubectl rollout status deployment/backend -n cuet-app

# Check rollout history
kubectl rollout history deployment/backend -n cuet-app
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/backend -n cuet-app

# Rollback to specific revision
kubectl rollout undo deployment/backend -n cuet-app --to-revision=2

# Verify
kubectl rollout status deployment/backend -n cuet-app
```

---

## Phase 8: Network & Ingress Testing

### Test from Inside Cluster

```bash
# Create a debug pod
kubectl run debug --image=curlimages/curl -i --tty --rm -n cuet-app -- sh

# Inside the pod, test services:
curl http://backend-service:3847/api/health
curl http://gateway-service:5921/health
curl http://elasticsearch-service:9200/_cluster/health
```

### Test Ingress

```bash
# Get Ingress details
kubectl get ingress -n cuet-app
kubectl describe ingress cuet-ingress -n cuet-app

# Test routes
MINIKUBE_IP=$(minikube ip)
curl http://$MINIKUBE_IP/api/health
curl http://$MINIKUBE_IP/kibana/api/status
```

---

## Troubleshooting Commands

### Pod Issues

```bash
# Describe pod for events
kubectl describe pod <pod-name> -n cuet-app

# Get logs
kubectl logs <pod-name> -n cuet-app

# Get previous logs (if crashed)
kubectl logs <pod-name> -n cuet-app --previous

# Execute into pod
kubectl exec -it <pod-name> -n cuet-app -- /bin/sh
```

### Service Discovery

```bash
# Check if service has endpoints
kubectl get endpoints -n cuet-app

# DNS lookup from inside cluster
kubectl run dns-test --image=busybox:1.28 -i --tty --rm -n cuet-app -- nslookup backend-service
```

### Resource Issues

```bash
# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -n cuet-app

# Describe node
kubectl describe node minikube
```

---

## Quick Health Check Script

Save as `health-check.sh`:

```bash
#!/bin/bash

echo "=== Checking Kubernetes Cluster ==="
kubectl cluster-info

echo "\n=== Checking Pods in cuet-app ==="
kubectl get pods -n cuet-app

echo "\n=== Checking Services ==="
kubectl get svc -n cuet-app

echo "\n=== Checking Ingress ==="
kubectl get ingress -n cuet-app

echo "\n=== Checking HPAs ==="
kubectl get hpa -n cuet-app

echo "\n=== Checking Prometheus Stack ==="
kubectl get pods -n monitoring

echo "\n=== Testing API Endpoint ==="
MINIKUBE_IP=$(minikube ip)
curl -s http://$MINIKUBE_IP/api/health || echo "API not reachable"

echo "\n=== Done ===" 
```

Run: `bash health-check.sh`

---

## Clean Up

### Stop Minikube

```bash
minikube stop
```

### Delete Everything

```bash
# Delete namespace (removes all resources)
kubectl delete namespace cuet-app

# Delete monitoring stack
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring

# Delete Minikube cluster
minikube delete
```

---

## Summary Checklist

- [ ] Minikube started and healthy
- [ ] All pods running in `cuet-app` namespace
- [ ] Ingress controller installed
- [ ] API accessible via Ingress
- [ ] Grafana accessible with dashboards
- [ ] Prometheus scraping metrics
- [ ] Kibana showing logs
- [ ] HPA scaling based on CPU
- [ ] Services can discover each other
- [ ] MinIO console accessible
- [ ] MongoDB connection working

**You're ready for production! 🚀**
