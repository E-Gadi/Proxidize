#!/bin/bash

set -e

IMAGE_NAME="${1:-service}"
IMAGE_TAG="${2:-latest}"
DEPLOYMENT_NAME="${3:-service}"
DEPLOYMENT_FILE="${4:-k8s/service}"
PORT="${5:-8088}"

echo "Using configuration:"
echo "  IMAGE_NAME=${IMAGE_NAME}"
echo "  IMAGE_TAG=${IMAGE_TAG}"
echo "  DEPLOYMENT_NAME=${DEPLOYMENT_NAME}"
echo "  DEPLOYMENT_FILE=${DEPLOYMENT_FILE}"
echo "  PORT=${PORT}"

create_venv_and_test() {
  echo "Creating Python virtual environment and installing requirements..."
  cd microservices/${IMAGE_NAME}

  if [ -d ".venv" ]; then
    echo ".venv already exists. Skipping creation."
  else
    python3 -m venv .venv
    echo "Created .venv"
  fi

  source .venv/bin/activate
  pip install --upgrade pip
  pip install -r requirements.txt
  pip install -r requirements-dev.txt

  echo "Dependencies installed inside .venv"
  cd ../..
  run_tests
  deactivate
}

run_tests() {
  echo "Running unit tests with coverage..."
  cd microservices/${IMAGE_NAME}

  if ! DISABLE_OTEL=true pytest; then
    echo "Tests failed. Aborting deployment."
    exit 1
  fi

  cd ../..
}

ensure_minikube_running() {
  echo "Checking if Minikube is running..."
  if ! minikube status | grep -q "host: Running"; then
    echo "Minikube is not running. Attempting to start it..."
    if ! minikube start; then
      echo "Minikube failed to start. Attempting to stop and restart..."
      minikube stop || true
      sleep 3
      if ! minikube start; then
        echo "Failed to start Minikube after restart attempt. Exiting."
        exit 1
      fi
    fi
  else
    echo "Minikube is already running."
  fi
}

build_image() {
  if docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format '{{.Repository}}:{{.Tag}}' | grep -q "${IMAGE_NAME}:${IMAGE_TAG}"; then
    echo "Removing existing image '${IMAGE_NAME}:${IMAGE_TAG}'..."
    docker rmi -f "${IMAGE_NAME}:${IMAGE_TAG}"
  fi

  cd microservices/${IMAGE_NAME}
  echo "Building Docker image without cache..."
  docker build --no-cache --pull -t "${IMAGE_NAME}:${IMAGE_TAG}" .
  cd ../..
}

delete_pods_and_image() {
  echo "Removing existing pods, deployment, and image from Minikube (if any)..."

  kubectl delete pods -l app="${DEPLOYMENT_NAME}" --grace-period=0 --force || true
  if kubectl get deployment "${DEPLOYMENT_NAME}" >/dev/null 2>&1; then
    kubectl delete deployment "${DEPLOYMENT_NAME}" || true
  fi
  if [ -f "${DEPLOYMENT_FILE}/deployment.yaml" ] || [ -d "${DEPLOYMENT_FILE}" ]; then
    kubectl delete -f "${DEPLOYMENT_FILE}" || true
  fi

  minikube ssh -- "docker rmi -f ${IMAGE_NAME}:${IMAGE_TAG}" || true
}

load_image_to_minikube() {
  echo "Loading Docker image into Minikube..."
  minikube ssh -- "if docker images \"${IMAGE_NAME}:${IMAGE_TAG}\" --format '{{.Repository}}:{{.Tag}}' | grep -q \"${IMAGE_NAME}:${IMAGE_TAG}\"; then
  echo 'Removing existing image ${IMAGE_NAME}:${IMAGE_TAG}...'
  docker rmi -f \"${IMAGE_NAME}:${IMAGE_TAG}\"
  fi" || true
  minikube image load "${IMAGE_NAME}:${IMAGE_TAG}"
}

apply_or_restart_deployment() {
  echo "Checking if deployment '${DEPLOYMENT_NAME}' exists..."
  if kubectl get deployment "${DEPLOYMENT_NAME}" >/dev/null 2>&1; then
    echo "Deployment exists. Restarting it..."
    kubectl rollout restart deployment "${DEPLOYMENT_NAME}"
  else
    echo "Deployment not found. Applying from manifest..."
    kubectl apply -f "${DEPLOYMENT_FILE}"
  fi
}

wait_for_rollout() {
  echo "Waiting for rollout to complete..."
  kubectl rollout status deployment "${DEPLOYMENT_NAME}"
}

port_forward_and_test() {
  if lsof -i :${PORT} >/dev/null 2>&1; then
    echo "Port ${PORT} is already in use!"
    lsof -i :${PORT}
    read -p "Do you want to kill the process using port ${PORT}? [y/N]: " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
      PID_TO_KILL=$(lsof -t -i :${PORT})
      echo "Killing process $PID_TO_KILL..."
      kill -9 $PID_TO_KILL
      sleep 2
    else
      echo "Cannot port-forward to ${PORT}. Exiting."
      return
    fi
  fi

  echo "Forwarding port ${PORT} from deployment '${DEPLOYMENT_NAME}' to localhost..."
  kubectl port-forward deployment/${DEPLOYMENT_NAME} ${PORT}:8080 &
  PORT_FORWARD_PID=$!
  sleep 3

  echo "Testing endpoint at http://localhost:${PORT}/health"
  curl --fail --silent http://localhost:${PORT}/health || echo "Health check failed!"

  echo "Port ${PORT} is now forwarded to http://localhost:${PORT}"
  echo "To stop the port-forwarding, run: kill ${PORT_FORWARD_PID}"
}

delete_resources() {
  echo "Deleting resources from k8s/${IMAGE_NAME}/..."
  kubectl delete -f "${DEPLOYMENT_FILE}"
}

show_menu() {
  echo
  echo "========= DevOps Menu ========="
  echo "1) Build Docker Image"
  echo "2) Delete Pods and Remove Image"
  echo "3) Load Image to Minikube"
  echo "4) Apply or Restart Deployment"
  echo "5) Wait for Rollout"
  echo "6) Port-forward & Test /health"
  echo "7) Run All Steps"
  echo "8) Delete Resources"
  echo "9) Run Tests"
  echo "10) Ensure Minikube Running"
  echo "q) Quit"
  echo "==============================="
  echo
}

main_loop() {
  while true; do
    show_menu
    read -p "Select an option: " choice
    case "$choice" in
    1) build_image ;;
    2) delete_pods_and_image ;;
    3) load_image_to_minikube ;;
    4) apply_or_restart_deployment ;;
    5) wait_for_rollout ;;
    6) port_forward_and_test ;;
    7)
      create_venv_and_test
      build_image
      delete_pods_and_image
      ensure_minikube_running
      load_image_to_minikube
      apply_or_restart_deployment
      wait_for_rollout
      port_forward_and_test
      ;;
    8) delete_resources ;;
    9) create_venv_and_test ;;
    10) ensure_minikube_running ;;
    q | Q)
      echo "Exiting."
      break
      ;;
    *)
      echo "Invalid option. Try again."
      ;;
    esac
  done
}

main_loop
