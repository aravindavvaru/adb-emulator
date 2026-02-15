# ADB Emulator on Kubernetes (Kind)

Run a headless Android emulator (Android 14) on a local Kubernetes cluster using Kind. Works on macOS and Linux — no KVM required.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Quick Start

```bash
bash commands.sh
```

This will:
1. Create a Kind cluster with ADB port mapping (5555)
2. Build the Android Emulator Docker image (~3GB, includes Android 14 system image)
3. Load the image into Kind
4. Deploy the emulator pod and service

## Connect via ADB

```bash
# Wait for the emulator to boot (5-10 min without KVM)
kubectl -n android-emulation logs -f deployment/android-emulator

# Once booted, connect from your host
adb connect localhost:5555

# Verify
adb devices
adb shell getprop ro.build.display.id
```

## How It Works

The emulator runs headless (`-no-window`) with software rendering (`swiftshader`). On hosts without KVM (like macOS Docker), it uses QEMU's TCG software emulation — slower but fully functional.

## Architecture

```
├── Dockerfile              # Debian 12 + Android SDK + emulator + system image
├── start-emulator.sh       # Entrypoint: launches emulator, waits for boot
├── commands.sh             # One-command setup script
├── kind.yaml               # Kind cluster config with ADB port mapping
└── manifests/
    ├── namespace.yaml      # android-emulation namespace
    ├── deployment.yaml     # Privileged pod with Recreate strategy
    └── service.yaml        # NodePort service (ADB: 30555 → 5555)
```

## Useful Commands

```bash
# Check pod status
kubectl -n android-emulation get pods

# Stream logs
kubectl -n android-emulation logs -f deployment/android-emulator

# Run shell commands on the emulator
adb shell

# Install an APK
adb install app.apk

# Take a screenshot
adb shell screencap /sdcard/screen.png && adb pull /sdcard/screen.png

# Restart the emulator
kubectl -n android-emulation rollout restart deployment android-emulator
```

## Cleanup

```bash
kind delete cluster --name android-emulator
```
