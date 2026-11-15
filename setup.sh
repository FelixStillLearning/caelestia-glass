#!/usr/bin/env bash
set -euo pipefail

# Skrip pemasangan dan sinkronisasi Caelestia Glass
echo "=== Memulai Setup Caelestia Glass ==="

SRC_DIR="$HOME/.local/src/caelestia-shell"
CONFIG_DIR="$HOME/.config/quickshell"

# 1. Periksa dependensi esensial
REQUIRED_TOOLS=("cmake" "ninja" "rofi" "ffmpeg" "python3" "hyprctl")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "[PERINGATAN] Perkakas '$tool' belum terpasang. Harap pasang terlebih dahulu."
    fi
done

# 2. Kompilasi plugin C++ jika direktori source tersedia
if [ -d "$SRC_DIR" ]; then
    echo "[-] Mengompilasi C++ Blobs plugin di $SRC_DIR..."
    cmake -S "$SRC_DIR" -B "$SRC_DIR/build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DENABLE_MODULES=plugin
    cmake --build "$SRC_DIR/build"
    echo "[OK] Kompilasi plugin selesai."
else
    echo "[INFO] Direktori $SRC_DIR belum ada. Harap klon fork caelestia-shell terlebih dahulu."
fi

# 3. Tautkan direktori shell
mkdir -p "$CONFIG_DIR"
if [ -d "$SRC_DIR" ]; then
    ln -sfn "$SRC_DIR" "$CONFIG_DIR/caelestia"
    echo "[OK] Tautan simbolik $CONFIG_DIR/caelestia -> $SRC_DIR berhasil dipasang."
fi

# 4. Sinkronisasi warna Rofi awal jika skema warna ada
if [ -f "$HOME/.local/bin/sync-caelestia-rofi.py" ]; then
    echo "[-] Menjalankan sinkronisasi warna Rofi..."
    python3 "$HOME/.local/bin/sync-caelestia-rofi.py" || true
    echo "[OK] Sinkronisasi warna selesai."
fi

# 5. Muat ulang konfigurasi Hyprland
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
    echo "[OK] Hyprland reload berhasil dieksekusi."
fi

echo "=== Setup Caelestia Glass Selesai ==="
