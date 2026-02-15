#!/bin/bash
set -e

echo "==================================="
echo "Android Emulator Starting"
echo "==================================="

# Check for emulator binary
if ! command -v emulator &> /dev/null; then
    echo "ERROR: emulator not found in PATH"
    echo "PATH: $PATH"
    tail -f /dev/null
    exit 1
fi

echo "Emulator: $(emulator -version | head -1)"
echo "ADB:      $(adb version | head -1)"

# List available AVDs
echo ""
echo "Available AVDs:"
emulator -list-avds

# Check KVM availability
KVM_FLAG=""
if [ -e /dev/kvm ]; then
    echo "KVM: available (hardware acceleration)"
else
    echo "KVM: not available (using software emulation — slower but works)"
    KVM_FLAG="-no-accel"
fi

echo ""
echo "Starting emulator..."
echo "==================================="

# Start ADB server
adb start-server

# Launch emulator in background
# -no-window:     headless mode (no GUI)
# -no-audio:      disable audio
# -no-boot-anim:  skip boot animation for faster startup
# -gpu swiftshader_indirect: software GPU rendering
# -no-snapshot:   fresh boot every time
# -memory 2048:   RAM for the emulator
emulator -avd android34 \
    -no-window \
    -no-audio \
    -no-boot-anim \
    -gpu swiftshader_indirect \
    -no-snapshot \
    -memory 2048 \
    -cores 2 \
    ${KVM_FLAG} \
    -read-only \
    -no-metrics \
    -port 5554 &

EMULATOR_PID=$!
echo "Emulator PID: $EMULATOR_PID"

# Wait for emulator to boot
echo "Waiting for emulator to boot (this may take a few minutes without KVM)..."
TIMEOUT=600
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if adb devices | grep -q "emulator-5554"; then
        BOOT_COMPLETED=$(adb -s emulator-5554 shell getprop sys.boot_completed 2>/dev/null || echo "")
        if [ "$BOOT_COMPLETED" = "1" ]; then
            echo ""
            echo "==================================="
            echo "Emulator booted successfully!"
            echo "==================================="
            echo ""
            adb -s emulator-5554 shell getprop ro.build.display.id
            echo ""
            echo "ADB device:"
            adb devices
            echo ""
            echo "Connect from host: adb connect localhost:5555"
            break
        fi
    fi
    sleep 5
    ELAPSED=$((ELAPSED + 5))
    echo "  waiting... (${ELAPSED}s / ${TIMEOUT}s)"
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "WARNING: Emulator did not fully boot within ${TIMEOUT}s"
    echo "It may still be booting. Check: adb devices"
fi

# Expose ADB on 0.0.0.0:5556 so Kubernetes service can reach it.
# The emulator binds ADB to 127.0.0.1:5555 only, so we use socat to bridge.
echo "Exposing ADB on 0.0.0.0:5556..."
socat TCP-LISTEN:5556,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:5555 &

# Keep container alive, follow emulator process
wait $EMULATOR_PID
