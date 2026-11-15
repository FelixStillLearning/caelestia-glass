# Panduan Pemasangan Caelestia Glass

Dokumen ini menjelaskan langkah-langkah instalasi dan konfigurasi Caelestia Glass untuk Hyprland.

---

## 1. Prasyarat Sistem

Pastikan paket dan dependensi berikut terpasang pada distribusi Linux Anda (Arch Linux / basis Arch):

### Paket Utama
- **Hyprland** (versi 0.45+ dengan dukungan layer blur)
- **Quickshell** (versi berbasis Qt 6.12+)
- **caelestia-cli** / lingkungan Caelestia
- **rofi-wayland**
- **ffmpeg** (dibutuhkan untuk pembuatan cache thumbnail wallpaper)
- **python** dan **python-pillow** (untuk ekstraksi palet warna)
- **cmake**, **ninja**, **gcc** / **clang** (untuk mengompilasi plugin C++ Blobs)

### Font
- **SF Pro Text** / **SF Pro Display**
- **Material Symbols Rounded**

Contoh instalasi dependensi pada Arch Linux:
```bash
sudo pacman -S cmake ninja gcc rofi-wayland ffmpeg python python-pillow
```

---

## 2. Pemasangan Fork Caelestia Shell

Caelestia Glass menggunakan fork dari `caelestia-shell` dengan modifikasi pada shader SDF dan modul QML.

### Langkah A: Kloning dan Build Fork
```bash
mkdir -p ~/.local/src
git clone -b glass https://github.com/FelixStillLearning/caelestia-shell.git ~/.local/src/caelestia-shell
cd ~/.local/src/caelestia-shell

# Konfigurasi dan kompilasi plugin C++
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DENABLE_MODULES=plugin
cmake --build build
```

### Langkah B: Tautkan Konfigurasi Quickshell
```bash
mkdir -p ~/.config/quickshell
ln -sfn ~/.local/src/caelestia-shell ~/.config/quickshell/caelestia
```

### Langkah C: Konfigurasi Autostart Hyprland
Agar plugin C++ yang telah dikompilasi termuat pada saat sistem memulai Caelestia shell, tambahkan environment variable `QML_IMPORT_PATH` pada autostart Anda.

Bila menggunakan konfigurasi Lua Caelestia (`~/.config/hypr/hyprland/execs.lua`):
```lua
-- Tambahkan atau ubah eksekusi Caelestia shell:
hl.exec_once("env QML_IMPORT_PATH=" .. os.getenv("HOME") .. "/.local/src/caelestia-shell/build/qml caelestia shell -d")
```

Bila menggunakan format `hyprland.conf` standar:
```ini
exec-once = env QML_IMPORT_PATH=$HOME/.local/src/caelestia-shell/build/qml caelestia shell -d
```

---

## 3. Konfigurasi Aturan Layer Hyprland

Efek kaca cair membutuhkan blur dan penyesuaian alpha pada level compositor.

Tambahkan aturan berikut pada konfigurasi aturan layer Anda (`~/.config/hypr/hyprland/rules.lua` atau `hyprland.conf`):

```lua
-- Aturan layer untuk Rofi (Wallpaper Picker & Menu Kaca)
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0.2, animation = "popin 90%" })

-- Aturan layer untuk Caelestia Shell
hl.layer_rule({ match = { namespace = "caelestia-(drawers|background)" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "caelestia-(border-exclusion|area-picker)" }, no_anim = true })
```

Atau dalam sintaks `hyprland.conf`:
```ini
layerrule = blur, rofi
layerrule = ignorealpha 0.2, rofi
layerrule = animation popin 90%, rofi

layerrule = animation fade, caelestia-(drawers|background)
layerrule = noanim, caelestia-(border-exclusion|area-picker)
```

Muat ulang konfigurasi Hyprland:
```bash
hyprctl reload
```

---

## 4. Pemasangan Rofi Wallpaper Picker (Super+W)

1. Salin berkas tema Rofi ke `~/.config/rofi/`:
   - `wallpaper-picker.rasi` (tampilan grid wallpaper)
   - `caelestia-menu.rasi` (dialog pemilihan kategori)
2. Salin skrip pembantu:
   - `wppicker.sh` ke `~/.config/hypr/scripts/wppicker.sh` (pastikan `chmod +x`)
   - `sync-caelestia-rofi.py` ke `~/.local/bin/sync-caelestia-rofi.py` (pastikan `chmod +x`)
3. Tautkan keybinding pada Hyprland (misal `SUPER + W`):
   ```lua
   hl.bind("SUPER + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/wppicker.sh"))
   ```

---

## 5. Menjalankan Ulang Shell

Untuk memuat ulang Caelestia Shell tanpa perlu logout:

```bash
# Pastikan layar tidak dalam keadaan terkunci
qs -c caelestia ipc call lock isLocked

# Hentikan shell yang berjalan lalu jalankan fork
killall -9 caelestia quickshell 2>/dev/null
env QML_IMPORT_PATH="$HOME/.local/src/caelestia-shell/build/qml" caelestia shell -d
```
