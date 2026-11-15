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

## Keputusan pertama untuk sesi berikutnya

Bagaimana mengubah shell tanpa hilang saat paket `caelestia-shell` diperbarui:

1. Salin `/etc/xdg/quickshell/caelestia` ke `~/.config/quickshell/caelestia` (salinan user diprioritaskan
   Quickshell), lalu ubah di sana. Sederhana, tetapi pembaruan paket tidak ikut masuk.
2. Fork repo upstream Caelestia shell dan pasang dari fork. Pembaruan upstream bisa di-merge.

Mulai dari satu komponen dulu (misalnya bar atau popup OSD volume) untuk membuktikan gayanya, baru menyebar.
