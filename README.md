# ADB Emulator on Kubernetes (Kind)

Run Android Cuttlefish virtual devices on a local Kubernetes cluster using Kind.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Quick Start

```bash
# Create cluster, build image, and deploy
bash commands.sh
```

This will:
1. Create a Kind cluster with port mappings for WebRTC (8443) and ADB (6520)
2. Build the Cuttlefish Docker image (Debian 12 + Cuttlefish v1.41.0)
3. Load the image into Kind
4. Deploy the namespace, deployment, and service

## Check Status

```bash
kubectl -n android-emulation get pods
kubectl -n android-emulation logs -f deployment/cuttlefish
```

## Loading Android Images

The container starts with Cuttlefish installed but needs Android system images to run a virtual device.

1. Go to [Android CI](https://ci.android.com/)
2. Navigate to **Branches → aosp-main → Grid**
3. Click a green build for `aosp_cf_x86_64_phone-userdebug`
4. Download:
   - `aosp_cf_x86_64_phone-img-XXXXXX.zip`
   - `cvd-host_package.tar.gz`
5. Copy images into the running pod:
   ```bash
   POD=$(kubectl -n android-emulation get pod -l app=cuttlefish -o jsonpath='{.items[0].metadata.name}')
   kubectl -n android-emulation cp ./aosp_cf_x86_64_phone-img-XXXXXX.zip $POD:/home/vsoc-01/android/
   kubectl -n android-emulation exec $POD -- unzip /home/vsoc-01/android/aosp_cf_x86_64_phone-img-XXXXXX.zip -d /home/vsoc-01/android/
   ```

## Architecture

```
├── Dockerfile              # Debian 12 + Cuttlefish from Google Artifact Registry
├── start-cuttlefish.sh     # Entrypoint: detects cvd/launch_cvd, launches emulator
├── commands.sh             # One-command setup script
├── kind.yaml               # Kind cluster config with port mappings
└── manifests/
    ├── namespace.yaml      # android-emulation namespace
    ├── deployment.yaml     # Privileged pod with Recreate strategy
    └── service.yaml        # NodePort service (WebRTC: 30443, ADB: 30550)
```

## Exposed Ports

| Port  | NodePort | Description |
|-------|----------|-------------|
| 8443  | 30443    | WebRTC UI   |
| 6520  | 30550    | ADB         |

## Cleanup

```bash
kind delete cluster --name cuttlefish-cluster
```
