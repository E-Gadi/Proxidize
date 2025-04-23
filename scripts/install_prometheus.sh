#!/bin/bash

NAMESPACE="monitoring"
PORT=9090
RETRIES=2

echo "Adding Prometheus Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "Creating monitoring namespace..."
kubectl create namespace $NAMESPACE || echo "Namespace $NAMESPACE already exists."

echo "Installing Prometheus..."
helm install prometheus prometheus-community/prometheus --namespace $NAMESPACE

echo "Waiting for Prometheus pods to be ready..."
kubectl wait --for=condition=ready pod -l app=prometheus-server --namespace $NAMESPACE --timeout=300s

if lsof -i :$PORT &>/dev/null; then
  echo "Port $PORT is already in use by the following process:"
  lsof -i :$PORT
  read -p "Do you want to kill the process using port $PORT? [y/N]: " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    PID=$(lsof -ti :$PORT)
    kill -9 $PID
    echo "Killed process $PID using port $PORT."
  else
    echo "Aborting port-forwarding setup. Prometheus can still be accessed via a different method."
    exit 1
  fi
fi

echo "Checking if Prometheus service is ready for port-forwarding..."

for ((i = 1; i <= RETRIES; i++)); do
  SERVICE_READY=$(kubectl get svc prometheus-server -n $NAMESPACE --output=jsonpath='{.spec.ports[0].port}' 2>/dev/null)
  if [[ -n "$SERVICE_READY" ]]; then
    echo "Prometheus service is ready."
    break
  fi
  echo "Prometheus service not yet ready. Retrying in 5 seconds ($i/$RETRIES)..."
  sleep 5
done

if [[ -z "$SERVICE_READY" ]]; then
  echo "Prometheus service did not become ready in time. Exiting."
  exit 1
fi

echo "Port-forwarding Prometheus to localhost:$PORT..."
kubectl port-forward -n $NAMESPACE svc/prometheus-server $PORT:80 &

sleep 5
echo "Prometheus is now accessible at http://localhost:$PORT"

echo "Installing Prometheus Node Exporter..."
helm install prometheus-node-exporter prometheus-community/prometheus-node-exporter --namespace $NAMESPACE

echo "Waiting for Node Exporter pods to be ready..."
kubectl wait --for=condition=ready pod -l app=prometheus-node-exporter --namespace $NAMESPACE --timeout=300s

echo "Prometheus and Node Exporter have been installed and are now running."
echo "You can access the Prometheus dashboard at http://localhost:$PORT"
