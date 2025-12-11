# Local Testing Quick Start (No VM Required)

Everything runs on your **Windows machine with Minikube**. No remote VM needed!

---

## Option 1: Test with Docker Compose (Fastest)

### Start Everything

```bash
# In project root
cd d:\devops\cuet-cse-fest-devops-hackathon-preli

# Start all services
docker-compose -f docker/compose.development.yaml up -d

# Wait 60 seconds for everything to start
```

### Access Services

Open your browser:

- **API**: http://localhost/api/health
- **NGINX**: http://localhost/health
- **Kibana**: http://localhost/kibana
- **MinIO Console**: http://localhost:9001 (minioadmin/minioadmin)
- **Sentry**: http://localhost:9002

### Check Running Services

```bash
docker-compose -f docker/compose.development.yaml ps
# Should see 11 containers running
```

### Stop

```bash
docker-compose -f docker/compose.development.yaml down
```

---

## Option 2: Test with Kubernetes (Minikube)

### 1. Start Minikube

```bash
minikube start --driver=docker --cpus=4 --memory=8192

# Verify
minikube status
```

### 2. Enable Ingress

```bash
minikube addons enable ingress
minikube addons enable metrics-server
```

### 3. Build Images in Minikube

```bash
# Point Docker to Minikube
minikube docker-env | Invoke-Expression

# Build images
docker build -t cuet-backend:latest ./backend
docker build -t cuet-gateway:latest ./gateway
```

### 4. Deploy to Kubernetes

```bash
cd k8s
bash setup.sh

# OR manually:
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-secrets.yaml
kubectl apply -f 02-configmaps.yaml
kubectl apply -f volumes/
kubectl apply -f deployments/
kubectl apply -f services/
kubectl apply -f ingress/
kubectl apply -f hpa/
```

### 5. Wait for Pods

```bash
kubectl get pods -n cuet-app --watch
# Wait until all are Running (2-3 minutes)
```

### 6. Get Minikube IP

```bash
minikube ip
# Example: 192.168.49.2
```

### 7. Access Services

Replace `<minikube-ip>` with your IP:

- **API**: http://`<minikube-ip>`/api/health
- **Kibana**: http://`<minikube-ip>`/kibana
- **Grafana** (after installing observability):
  ```bash
  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
  # http://localhost:3000 (admin/admin)
  ```

---

## Option 3: Install Observability Stack (Optional)

### Install Prometheus + Grafana

```bash
cd k8s/observability

# Install
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
bash install.sh
```

### Access Grafana

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

**Browser**: http://localhost:3000
- Username: `admin`
- Password: `admin`

**Import Dashboards**:
1. Grafana → + → Import
2. Upload JSON from `k8s/observability/dashboards/`

### Access Prometheus

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

**Browser**: http://localhost:9090

---

## Quick Health Checks

### Docker Compose Status

```bash
docker-compose -f docker/compose.development.yaml ps
curl http://localhost/api/health
```

### Kubernetes Status

```bash
kubectl get all -n cuet-app
kubectl get hpa -n cuet-app
minikube ip
curl http://$(minikube ip)/api/health
```

---

## Tips

### Faster Testing
- **Docker Compose** is faster for initial testing (30 seconds)
- **Kubernetes** is for full production simulation (3-5 minutes)

### If Minikube is Slow
```bash
# Increase resources
minikube delete
minikube start --driver=docker --cpus=6 --memory=10240
```

### View Logs
```bash
# Docker
docker-compose -f docker/compose.development.yaml logs backend

# Kubernetes
kubectl logs -n cuet-app -l app=backend --tail=50
```

---

## What You Can Test Locally

✅ All 11 services running  
✅ NGINX reverse proxy  
✅ Ingress routing  
✅ HPA autoscaling (simulate load)  
✅ Rolling updates & rollbacks  
✅ Prometheus metrics  
✅ Grafana dashboards  
✅ Kibana log viewing  
✅ Service discovery  
✅ Persistent volumes  

**No VM, no cloud, no remote servers needed!** 🎉
