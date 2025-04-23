#!/bin/bash

set -e

# === Configuration ===
IMAGE_NAME="length-service"
IMAGE_TAG="latest"
DEPLOYMENT_NAME="length-service"
DEPLOYMENT_FILE="k8s/length-service"
PORT="8081"

# === Run the main deployment menu ===
./scripts/_deploy.sh "$IMAGE_NAME" "$IMAGE_TAG" "$DEPLOYMENT_NAME" "$DEPLOYMENT_FILE" "$PORT"
