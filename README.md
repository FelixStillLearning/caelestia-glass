# Caelestia Glass

> Varian tema kaca cair (*macOS-inspired Liquid Glass*) untuk Caelestia Shell dan Hyprland.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Hyprland](https://img.shields.io/badge/Compositor-Hyprland-brightgreen.svg)](https://hyprland.org)
[![Quickshell](https://img.shields.io/badge/Framework-Quickshell-purple.svg)](https://quickshell.outfoxxed.me)

---

## Gambaran Umum

**Caelestia Glass** mentransformasikan Caelestia Shell dari estetika datar Material 3 menjadi tampilan kaca tembus pandang (*liquid glass*) ala macOS. Bar, drawer, popout, notification center, lockscreen, hingga pemilih wallpaper Rofi disatukan di bawah satu bahasa visual yang kohesif:

- **Kaca Tembus Pandang**: Latar belakang diburamkan oleh Hyprland (`blur = true`, `ignore_alpha = 0.2`) dengan lapisan warna dinamis yang tipis (*translucent surface*).
- **Tepi Bercahaya (*Specular Rim*)**: Garis putih lembut 1.2 px mengikuti kontur bentuk dan arah pencahayaan.
- **Kilau Lembut (*Sheen*)**: Gradasi pantulan memudar halus 20 px ke dalam permukaan kaca.
- **Transisi Pegas Alami**: Animasi ekspansi dan kontraksi bentuk menempel ke tepi layar.
- **Palet Warna Adaptif**: Mengikuti skema warna wallpaper aktif melalui integrasi otomatis Matugen.

---

## Galeri Tangkapan Layar

| Rofi Wallpaper Picker (Super+W) | Menu Kategori Kaca |
| :---: | :---: |
| ![Wallpaper Picker](screenshots/15-rofi-grid.png) | ![Kategori Menu](screenshots/16-rofi-category.png) |

| Utilities & Quick Settings | Notification Center |
| :---: | :---: |
| ![Utilities](screenshots/09-glass-utilities.png) | ![Notification](screenshots/09-glass-notification.png) |

| Lockscreen Kaca Cair | OSD & Bingkai Layar |
| :---: | :---: |
| ![Lock Screen](screenshots/12-lock-live.png) | ![OSD Glass](screenshots/08-glass-frame-osd.png) |

---

## Fitur Utama

1. **Shader Kaca Terpadu (SDF C++ Plugin)**
   - Menggunakan snapshot *Signed Distance Field* (SDF) tunggal untuk menggambar bingkai layar dan seluruh panel drawer.
   - Tidak ada celah antar-mesh atau penumpukan tint saat beberapa panel saling bersentuhan atau bertransisi.

2. **Rofi Wallpaper Picker Bergaya macOS Spotlight**
   - Bilah pencarian berbentuk kapsul (pill) di bagian atas.
   - Menghasilkan thumbnail squircle HiDPI (480x480) bersudut melengkung halus lewat ffmpeg.
   - Mengisi kartu 240px secara proporsional tanpa celah kosong vertikal.
   - Dialog pemilihan kategori warna dan folder dengan latar kaca 440px.

3. **Komponen Shell QML yang Diselaraskan**
   - **Lockscreen**: Jam minimalis, input kata sandi transparan, dan label pengguna yang bersih.
   - **Launcher & Nexus**: Kartu wallpaper proporsional dengan border seleksi dan indikator centang dinamis.
   - **SDDM Login Theme**: Berkas tema `Main.qml` terpadu dengan efek blur latar belakang.

4. **Efisiensi & Performa Teruji**
   - Berjalan pada ~60 FPS dengan lonjakan minimal. Penggunaan GPU berkisar antara 5.1–11.6% pada skenario aktif. Detail pengukuran tersedia di [reports/performance-2026-11-15.md](reports/performance-2026-11-15.md).

---

## Struktur Proyek

Proyek ini terbagi ke dalam komponen berikut:

- **[caelestia-glass](https://github.com/FelixStillLearning/caelestia-glass)**: Repository pusat dokumentasi, aset, tema SDDM, dan panduan instalasi.
- **[caelestia-shell (branch: glass)](https://github.com/FelixStillLearning/caelestia-shell/tree/glass)**: Fork dari Caelestia Shell yang memuat modifikasi shader SDF C++ dan modul QML.
- **[caelestia-hypr-backup](https://github.com/FelixStillLearning/caelestia-hypr-backup)**: Referensi konfigurasi dotfiles lengkap (Hyprland, Rofi, skrip wallpaper).

---

## Panduan Instalasi Cepat

### Prasyarat
- Hyprland 0.45+ (dengan dukungan layer blur)
- Quickshell (Qt 6.12+)
- `cmake`, `ninja`, `gcc`
- `rofi-wayland`, `ffmpeg`, `python-pillow`
- Font: `SF Pro Text`, `Material Symbols Rounded`

### Instalasi
1. Klon repository ini:
   ```bash
   git clone https://github.com/FelixStillLearning/caelestia-glass.git
   cd caelestia-glass
   ```

2. Jalankan skrip setup otomatis:
   ```bash
   ./setup.sh
   ```

Untuk panduan pemasangan manual langkah-demi-langkah, silakan baca **[INSTALL.md](INSTALL.md)**.

---

## Dokumentasi Teknis

Catatan riset, analisis matematis shader, dan riwayat iterasi pengembangan didokumentasikan secara lengkap pada **[docs/DEVELOPMENT_LOG.md](docs/DEVELOPMENT_LOG.md)**.

---

## Lisensi dan Atribusi

- Dilisensikan di bawah [GNU General Public License v3.0](LICENSE).
- Basis shell didasarkan pada [Caelestia Shell](https://github.com/caelestia-dots/shell) oleh tim Caelestia.
- Acuan desain outline dan lekukan kaca terinspirasi dari konsep notch Jarvis.
