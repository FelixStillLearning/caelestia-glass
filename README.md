# caelestia-glass

Mengubah tampilan Caelestia shell supaya bergaya kaca cair ala macOS, mengikuti notch Jarvis.

## Tujuan

Bar, drawer, popup, dan panel Caelestia memakai bahasa visual yang sama dengan notch Jarvis:

- kaca tembus pandang: latar di belakangnya diburamkan oleh Hyprland (layer rule `blur` + `ignore_alpha`),
  di atasnya warna `surface` tipis (alpha sekitar 0.38)
- tepi bercahaya: garis 1.2 px dengan gradien, paling terang di sudut, redup di tengah
- kilau lembut di sudut bawah dan cahaya yang terkumpul di dasar kaca
- bentuk menempel ke tepi layar dengan lekukan cekung (seperti notch MacBook)
- gerak pegas saat melebar/menyusut
- warna tetap dari skema Caelestia (ikut wallpaper)

Acuan kode: `reference/jarvis-island-notch.qml` (bagian `Shape` berlapis dan `outline` SVG).

## Kondisi awal (2026-11-15)

- Caelestia shell 2.5.0 dari paket `caelestia-shell`, terpasang di `/etc/xdg/quickshell/caelestia`
  (Quickshell/QML, sekitar 282 berkas). Modul: `bar`, `drawers`, `dashboard`, `launcher`, `notifications`,
  `osd`, `sidebar`, `session`, `lock`, `utilities`, dan lain-lain.
- Pengaturan user: `~/.config/caelestia/shell.json` (`appearance.transparency.enabled = true`).
- Layer rule Caelestia di `~/.config/hypr/hyprland/rules.lua`: `caelestia-(drawers|background)` baru diberi
  animasi fade, belum diberi blur.
- Hyprland 0.57 dengan config Lua (`hl.layer_rule`, `hl.dsp.*`). Qt 6.12, jadi `ShapePath.strokeGradient` tersedia.
- Jarvis sudah di-uninstall; notch-nya sendiri tidak berjalan. Arsip lengkap ada di repo
  `caelestia-hypr-backup` (branch `main`).

## Keputusan: fork (2026-11-15)

Semua latar (bingkai layar, bar, dan semua panel) digambar oleh satu `BlobGroup` di
`modules/drawers/ContentWindow.qml`, dengan shader SDF di plugin C++ (`plugin/src/Caelestia/Blobs/shaders/blob.frag`).
Tepi dan kilau hanya bisa dibuat sekali untuk semua di shader itu, jadi dipilih fork.

- Fork: `~/.local/src/caelestia-shell`, branch `glass` dari tag upstream `v2.5.0`, remote `upstream`.
  Belum ada fork di GitHub.
- Build plugin: `cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DENABLE_MODULES=plugin`, lalu
  `cmake --build build`.
- Jalankan fork untuk uji (cek dulu `qs -c caelestia ipc call lock isLocked` harus `false`, karena lockscreen
  ada di dalam shell): `caelestia shell -k`, lalu `QML_IMPORT_PATH=~/.local/src/caelestia-shell/build/qml qs -p ~/.local/src/caelestia-shell -n`.
- Kembali ke shell paket: `qs -p ~/.local/src/caelestia-shell kill`, lalu `caelestia shell -d`.
- Belum dipasang permanen. `/etc`, `/usr`, `~/.config`, dan `execs.lua` tidak diubah.

## Progres

1. Prototipe kaca pada OSD (commit fork `5ee9f2fe`). Hasilnya: kaca buram, tepi 1.2 px terang di sudut,
   dan kilau sudut bawah. Lihat `screenshots/05-compare-osd.png` (kiri sebelum, kanan sesudah).
   Batasan: bayangan `MultiEffect` tertumpuk di bawah kaca, jadi alpha terukur 0.44 (target 0.38), dan ada
   pita gelap di dekat bingkai.

2. Langkah 1: bayangan hanya di luar bentuk (commit fork `4dd8121d`).
   `MultiEffect` diganti falloff SDF pada bentuk gabungan, dipotong dengan coverage geometrinya;
   bayangan tidak ikut menambah tint kaca. Warna bayangan tetap dari skema dan memudar saat fullscreen.
   Piksel di pertemuan panel/bingkai sekarang hanya digambar oleh satu renderer, menghilangkan
   penumpukan transparansi. Kompensasi alpha untuk bayangan lama dihapus.
   Render PNG terisolasi mengukur tint bagian atas OSD sebesar 97/255 (sekitar 0.38);
   tepi dan kilau bawah memang menambah alpha. Bayangan dibatasi 15 px atau padding smoothing
   bila lebih kecil. Lihat `screenshots/07-outer-shadow-osd.png` untuk hasil di desktop.
   Bingkai dan bar masih memakai material awal; perubahan keduanya adalah langkah berikutnya.

   Verifikasi: build plugin/shader berhasil; tes render `tests/tst_blobshadow.qml` di fork lulus
   (tint dan sambungan panel/bingkai, bayangan di luar bentuk, piksel bagian dalam tidak berubah,
   dan bayangan hilang saat warnanya transparan). Shader lama gagal pada tes tint yang sama.
   Jalankan dari direktori fork dengan display aktif:

   ```sh
   QML_IMPORT_PATH="$PWD/build/qml" QSG_RHI_BACKEND=opengl /usr/lib/qt6/bin/qmltestrunner -input tests
   ```

   Uji shell singkat juga berhasil membuka OSD tanpa error di log. Sesudah uji, shell paket
   diaktifkan kembali. Fork belum diaktifkan permanen; konfigurasi autostart belum diubah.
