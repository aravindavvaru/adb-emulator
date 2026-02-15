#!/bin/bash
set -e

CLUSTER_NAME="android-emulator"
IMAGE_NAME="android-emulator:v1"

# Create kind cluster (skip if already exists)
kind get clusters 2>/dev/null | grep -q "$CLUSTER_NAME" || kind create cluster --config kind.yaml

# Build Docker image
docker build -t $IMAGE_NAME .

# Load image into kind (required since imagePullPolicy: Never)
kind load docker-image $IMAGE_NAME --name $CLUSTER_NAME

# Deploy manifests
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/deployment.yaml
kubectl apply -f manifests/service.yaml

echo ""
echo "Waiting for pod to start..."
kubectl -n android-emulation wait --for=condition=Ready pod -l app=android-emulator --timeout=120s 2>/dev/null || \
    echo "Pod not ready yet, check: kubectl -n android-emulation get pods"
kubectl -n android-emulation get pods

echo ""
echo "To check logs:  kubectl -n android-emulation logs -f deployment/android-emulator"
echo "To connect ADB: adb connect localhost:5555"
