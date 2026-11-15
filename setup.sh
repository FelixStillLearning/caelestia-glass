#!/usr/bin/env bash
set -euo pipefail

# Caelestia Glass build and synchronization helper
echo "=== Starting Caelestia Glass setup ==="

SRC_DIR="$HOME/.local/src/caelestia-shell"
CONFIG_DIR="$HOME/.config/quickshell"

# 1. Check essential tools
REQUIRED_TOOLS=("cmake" "ninja" "rofi" "ffmpeg" "python3" "hyprctl")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "[WARNING] Tool '$tool' is missing. Install it before continuing."
    fi
done

# 2. Build the C++ plugin if the source directory exists
if [ -d "$SRC_DIR" ]; then
    echo "[-] Building the C++ Blobs plugin in $SRC_DIR..."
    cmake -S "$SRC_DIR" -B "$SRC_DIR/build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DENABLE_MODULES=plugin
    cmake --build "$SRC_DIR/build"
    echo "[OK] Plugin build complete."
else
    echo "[INFO] Directory $SRC_DIR does not exist. Clone the caelestia-shell fork first."
fi

# 3. Link the shell directory
mkdir -p "$CONFIG_DIR"
if [ -d "$SRC_DIR" ]; then
    ln -sfn "$SRC_DIR" "$CONFIG_DIR/caelestia"
    echo "[OK] Created symlink $CONFIG_DIR/caelestia -> $SRC_DIR."
fi

# 4. Synchronize initial Rofi colors if a color scheme exists
if [ -f "$HOME/.local/bin/sync-caelestia-rofi.py" ]; then
    echo "[-] Synchronizing Rofi colors..."
    python3 "$HOME/.local/bin/sync-caelestia-rofi.py" || true
    echo "[OK] Color synchronization complete."
fi

# 5. Reload the Hyprland configuration
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
    echo "[OK] Hyprland reload requested."
fi

echo "=== Caelestia Glass setup finished ==="
