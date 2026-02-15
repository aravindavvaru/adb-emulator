#!/bin/bash
set -e

# Create kind cluster (skip if already exists)
kind get clusters 2>/dev/null | grep -q cuttlefish-cluster || kind create cluster --config kind.yaml

# Build Docker image
docker build -t cuttlefish:v1 .

# Load image into kind (required since imagePullPolicy: Never)
kind load docker-image cuttlefish:v1 --name cuttlefish-cluster

# Deploy manifests
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/deployment.yaml
kubectl apply -f manifests/service.yaml

echo ""
echo "Waiting for pod to start..."
kubectl -n android-emulation wait --for=condition=Ready pod -l app=cuttlefish --timeout=120s 2>/dev/null || \
    echo "Pod not ready yet, check: kubectl -n android-emulation get pods"
kubectl -n android-emulation get pods