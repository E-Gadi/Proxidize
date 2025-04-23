#!/bin/bash

set -euo pipefail

PORT=8088
NAMESPACE=default
RELEASE_NAME=jaeger
CHART_REPO_NAME=jaegertracing
CHART_REPO_URL=https://jaegertracing.github.io/helm-charts
CHART_NAME=$CHART_REPO_NAME/jaeger

is_port_in_use() {
  lsof -i :$1 >/dev/null 2>&1
}

kill_process_using_port() {
  echo "Port $PORT is already in use. Do you want to kill the process using this port? (y/n): "
  read answer
  if [[ "$answer" == "y" ]]; then
    PID=$(lsof -t -i :$PORT)
    echo "Killing process $PID using port $PORT..."
    kill -9 $PID
  else
    echo "Aborting port-forwarding due to port conflict."
    exit 1
  fi
}

build_jaeger() {
  echo "Installing Jaeger..."

  helm repo add $CHART_REPO_NAME $CHART_REPO_URL 2>/dev/null || true
  helm repo update

  if ! helm status $RELEASE_NAME -n $NAMESPACE >/dev/null 2>&1; then
    echo "Installing Jaeger via Helm..."
    helm install $RELEASE_NAME $CHART_NAME \
      --namespace $NAMESPACE \
      --set allInOne.enabled=true \
      --set agent.enabled=true \
      --set collector.enabled=true \
      --set query.enabled=true \
      --set provisionDataStore.cassandra=false \
      --set storage.type=memory
  else
    echo "Jaeger is already installed. Restarting deployment..."
    kubectl rollout restart deployment $RELEASE_NAME -n $NAMESPACE

    echo "Force-deleting all Jaeger pods to ensure fresh startup..."
    kubectl delete pod -l app.kubernetes.io/instance=$RELEASE_NAME -n $NAMESPACE
  fi

  echo "Waiting for Jaeger pods to be ready..."
  kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/instance=$RELEASE_NAME \
    -n $NAMESPACE \
    --timeout=300s

  POD_NAME=$(kubectl get pods -n $NAMESPACE \
    -l "app.kubernetes.io/name=jaeger,app.kubernetes.io/instance=$RELEASE_NAME" \
    -o jsonpath="{.items[0].metadata.name}")

  echo "Checking if port $PORT is in use..."
  if is_port_in_use $PORT; then
    kill_process_using_port
  fi

  echo "Port-forwarding to Jaeger UI pod: $POD_NAME"
  kubectl port-forward --namespace $NAMESPACE pod/$POD_NAME $PORT:16686 &
  echo "Jaeger Query UI is now accessible at: http://127.0.0.1:$PORT/"
}

clean_jaeger() {
  echo "Cleaning Jaeger..."

  echo "Force-deleting all Jaeger pods to ensure fresh startup..."
  kubectl delete pod -l app.kubernetes.io/instance=$RELEASE_NAME -n $NAMESPACE

  echo "Waiting for Jaeger pods to be ready..."
  kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/instance=$RELEASE_NAME \
    -n $NAMESPACE \
    --timeout=300s

  POD_NAME=$(kubectl get pods -n $NAMESPACE \
    -l "app.kubernetes.io/name=jaeger,app.kubernetes.io/instance=$RELEASE_NAME" \
    -o jsonpath="{.items[0].metadata.name}")

  echo "Checking if port $PORT is in use..."
  if is_port_in_use $PORT; then
    kill_process_using_port
  fi

  echo "Port-forwarding to Jaeger UI pod: $POD_NAME"
  kubectl port-forward --namespace $NAMESPACE pod/$POD_NAME $PORT:16686 &
  echo "Jaeger Query UI is now accessible at: http://127.0.0.1:$PORT/"
}

read -p "Do you want to build (install/update) or clean (force delete) Jaeger? (build/clean): " action

if [[ "$action" == "build" ]]; then
  build_jaeger
elif [[ "$action" == "clean" ]]; then
  clean_jaeger
else
  echo "Invalid action. Please specify 'build' or 'clean'."
  exit 1
fi