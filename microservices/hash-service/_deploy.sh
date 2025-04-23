#!/bin/bash

set -e

# === Configuration ===
IMAGE_NAME="hash-service"
IMAGE_TAG="latest"
DEPLOYMENT_NAME="hash-service"
DEPLOYMENT_FILE="k8s/hash-service"
PORT="8080"

# === Run the main deployment menu ===
./scripts/_deploy.sh "$IMAGE_NAME" "$IMAGE_TAG" "$DEPLOYMENT_NAME" "$DEPLOYMENT_FILE" "$PORT"
