#!/bin/bash
set -e

echo "==================================="
echo "Cuttlefish Container Starting"
echo "==================================="

# Check for cuttlefish binaries (cvd is the new tool, launch_cvd is legacy)
echo "Searching for Cuttlefish binaries..."

CVD_CMD=""
if command -v cvd &> /dev/null; then
    CVD_CMD="cvd"
    echo "✓ cvd found at: $(which cvd)"
elif command -v launch_cvd &> /dev/null; then
    CVD_CMD="launch_cvd"
    echo "✓ launch_cvd found at: $(which launch_cvd)"
else
    echo "❌ Neither cvd nor launch_cvd found in PATH"
    echo ""
    echo "Debugging info:"
    echo "PATH: $PATH"
    echo ""
    echo "Installed cuttlefish packages:"
    dpkg -l | grep cuttlefish || echo "No cuttlefish packages found"
    echo ""
    echo "Container staying alive for debugging..."
    tail -f /dev/null
    exit 1
fi

# Check for Android images
cd /home/vsoc-01
mkdir -p /home/vsoc-01/cuttlefish_runtime

if [ ! -d "/home/vsoc-01/android" ] || [ -z "$(ls -A /home/vsoc-01/android 2>/dev/null)" ]; then
    echo ""
    echo "==================================="
    echo "Ready - Waiting for Android Images"
    echo "==================================="
    echo ""
    echo "✓ Cuttlefish binaries installed and working ($CVD_CMD)"
    echo "✗ Android system images not found"
    echo ""
    echo "Next steps to run Android:"
    echo "1. Download images from: https://ci.android.com/"
    echo "   Navigate to: Branches -> aosp-main -> Grid"
    echo "   Click a green build for: aosp_cf_x86_64_phone-userdebug"
    echo "   Download: aosp_cf_x86_64_phone-img-XXXXXX.zip"
    echo "   Also download: cvd-host_package.tar.gz (from same build)"
    echo ""
    echo "2. Create a PersistentVolume or hostPath with the images"
    echo "3. Mount to /home/vsoc-01/android in the pod"
    echo ""
    echo "Container will stay running for debugging..."
    echo ""
    echo "Pod info:"
    echo "  Hostname: $(hostname)"
    echo "  Cuttlefish tool: $CVD_CMD"
    dpkg -l | grep cuttlefish
    echo ""
    tail -f /dev/null
fi

echo "✓ Android images found at /home/vsoc-01/android"
echo "Launching Cuttlefish..."

if [ "$CVD_CMD" = "cvd" ]; then
    # Use the new cvd tool
    cvd start \
        --cpus=2 \
        --memory_mb=2048 \
        --data_policy=always_create \
        --blank_data_image_mb=4096 \
        --gpu_mode=guest_swiftshader \
        --start_webrtc=true \
        --report_anonymous_usage_stats=n 2>&1 | tee /tmp/launch.log || {
        echo "❌ Cuttlefish launch failed"
        echo "Recent logs:"
        tail -50 /tmp/launch.log
        echo ""
        echo "Container staying alive for debugging..."
        tail -f /dev/null
    }
else
    # Legacy launch_cvd
    launch_cvd \
        --daemon \
        --cpus=2 \
        --memory_mb=2048 \
        --data_policy=always_create \
        --blank_data_image_mb=4096 \
        --gpu_mode=guest_swiftshader \
        --start_webrtc=true \
        --webrtc_public_ip=0.0.0.0 \
        --webrtc_enable_adb_websocket=true \
        --report_anonymous_usage_stats=n 2>&1 | tee /tmp/launch.log || {
        echo "❌ Cuttlefish launch failed"
        echo "Recent logs:"
        tail -50 /tmp/launch.log
        echo ""
        echo "Container staying alive for debugging..."
        tail -f /dev/null
    }
fi

echo "✓ Cuttlefish launched successfully!"
echo "WebRTC: https://0.0.0.0:8443"

# Monitor
tail -f /home/vsoc-01/cuttlefish_runtime/cuttlefish/instances/cvd-1/logs/launcher.log 2>/dev/null || tail -f /dev/null
