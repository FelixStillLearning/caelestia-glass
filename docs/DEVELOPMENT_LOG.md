# caelestia-glass

Mengubah tampilan Caelestia shell supaya bergaya kaca cair ala macOS, mengikuti notch Jarvis.

## Tujuan

Bar, drawer, popup, dan panel Caelestia memakai bahasa visual yang sama dengan notch Jarvis:

- kaca tembus pandang: latar di belakangnya diburamkan oleh Hyprland (layer rule `blur` + `ignore_alpha`),
  di atasnya warna `surface` tipis (alpha sekitar 0.38)
- tepi bercahaya: garis putih lembut 1.2 px mengikuti kontur dan arah cahaya
- kilau halus memudar 20 px ke dalam kaca
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
- Aktif permanen sejak 2026-11-15: `~/.config/quickshell/caelestia` adalah symlink ke fork.
  Autostart di `~/.config/hypr/hyprland/execs.lua` menjalankan
  `env QML_IMPORT_PATH=${HOME}/.local/src/caelestia-shell/build/qml caelestia shell -d`.
- Cadangan autostart asli: `~/.local/state/caelestia-glass/backups/20261115-133303/execs.lua`.
  Metadata aktivasi dan lokasi plugin tersimpan di `~/.local/state/caelestia-glass/activation.json`.
- `/etc` dan `/usr` tetap memakai paket sistem; perubahan konfigurasi hanya pada user.

Untuk restart manual, periksa `qs -c caelestia ipc call lock isLocked` terlebih dahulu. Lanjutkan hanya
jika hasilnya `false`, karena lockscreen ada di dalam shell. Sertakan lokasi plugin hasil build:

```sh
QML_IMPORT_PATH="$HOME/.local/src/caelestia-shell/build/qml" caelestia shell -r -d
```

Untuk kembali ke shell paket: ketika sesi tidak terkunci, hentikan fork dengan `qs -c caelestia kill`,
hapus hanya symlink `~/.config/quickshell/caelestia`, ubah perintah autostart kembali menjadi
`caelestia shell -d`, lalu jalankan `caelestia shell -d`. Cadangan tersedia untuk membandingkan isi
`execs.lua`; jangan menimpa perubahan lain yang dibuat setelah aktivasi.

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
   Pada langkah ini bingkai dan bar masih memakai material awal; perubahan keduanya dilanjutkan di langkah 2.

   Verifikasi: build plugin/shader berhasil; tes render `tests/tst_blobshadow.qml` di fork lulus
   (tint dan sambungan panel/bingkai, bayangan di luar bentuk, piksel bagian dalam tidak berubah,
   dan bayangan hilang saat warnanya transparan). Shader lama gagal pada tes tint yang sama.
   Jalankan dari direktori fork dengan display aktif:

   ```sh
   QML_IMPORT_PATH="$PWD/build/qml" QSG_RHI_BACKEND=opengl /usr/lib/qt6/bin/qmltestrunner -input tests
   ```

   Uji shell singkat juga berhasil membuka OSD tanpa error di log. Sesudah uji, shell paket
   diaktifkan kembali. Fork belum diaktifkan permanen; konfigurasi autostart belum diubah.


3. Langkah 2: bingkai layar dan bar kaca (commit fork `ade50e78`).
   `BlobInvertedRect.glass` yang sudah ada sekarang dikirim ke shader, memakai tint 0.38, tepi
   1.2 px, dan kilau yang sama dengan OSD. Bar memakai latar bingkai ini sehingga tidak perlu
   lapisan atau pengaturan tambahan. Tint dibaurkan di sambungan dengan OSD dan panel biasa;
   panel lain masih memakai material awal. Saat transparansi dimatikan, bingkai kembali ke
   material awal melalui binding yang sama.

   Jalur mesh cincin bingkai kini menerima warna bayangan. Peralihan ke quad saat lubang bingkai
   terlalu kecil juga membangun ulang geometry agar indeks mesh lama tidak menggambar tint dua kali.
   Tes render `tests/tst_frameglass.qml` mencakup bar/bingkai, sambungan OSD, panel biasa,
   bayangan luar bingkai, kedua arah peralihan mesh, dan glass dimatikan, dengan alpha dasar 1 dan 0.8.
   Build berhasil dan seluruh tes render lulus (7 hasil PASS termasuk setup/cleanup).
   Uji shell singkat berhasil membuka OSD dan launcher tanpa error pada log fork.

   Crop desktop terbaru: `screenshots/08-glass-bar.png` dan `screenshots/08-glass-frame-osd.png`.
   Shell paket sudah aktif kembali; autostart belum diubah. Fullscreen belum diuji langsung.
   Berikutnya: terapkan material kaca pada panel lain.


4. Langkah 3: latar semua panel drawer utama memakai kaca (commit fork `4f89901d`).
   Binding `glass` dipindahkan dari OSD ke komponen bersama `PanelBg`, sehingga dashboard,
   launcher, session, sidebar, notifikasi, utilities, dan popout memakai material kaca yang sama.
   Kartu isi, kontrol, dan warna penanda notifikasi kritis tetap memakai warna semula.

   Shader kini membaurkan kontribusi semua panel terdekat dan menormalisasi bobotnya. Ini menjaga
   tint pada 0.38 ketika dua atau tiga panel kaca bertemu. Panel yang dikecualikan dari pembauran
   bentuk (sidebar/utilities) tetap ikut menentukan pemilik piksel, sehingga bagian tumpang tindih
   tidak digambar dua kali. Mask exclusion tetap menjaga sudutnya tidak dibaurkan.

   Tes baru `tests/tst_panelglass.qml` mula-mula gagal pada keempat kasus dengan shader lama,
   lalu lulus setelah perbaikan: dua panel, alpha dasar 0.8, tiga panel bertumpuk, dan panel excluded.
   Build berhasil; seluruh 7 kasus render lulus (13 hasil PASS termasuk setup/cleanup).
   Uji desktop berhasil membuka/menutup launcher, dashboard, session, utilities, dan sidebar,
   termasuk sidebar bersama utilities, serta menampilkan notifikasi uji lokal. Dashboard sempat
   tertutup oleh interaksi hover pada percobaan awal dan berhasil dibuka pada percobaan berikutnya.
   Log fork tidak menunjukkan error QML/shader. Notifikasi uji ditutup setelah pengambilan gambar.

   Crop hasil tanpa riwayat notifikasi pribadi: `screenshots/09-glass-utilities.png` dan
   `screenshots/09-glass-notification.png`. Shell paket sudah aktif kembali; autostart belum diubah.
   Fullscreen dan seluruh variasi popout belum diuji langsung. Editor Nexus terpisah, lockscreen,
   serta toast tetap memakai materialnya sendiri.


5. Langkah 4: verifikasi fullscreen/popout dan aktivasi permanen (2026-11-15).
   Jendela uji Qt 6 dipindahkan masuk/keluar fullscreen tanpa mengubah jendela pengguna.
   Saat fullscreen, lima sampel tepi layar sama dengan warna jendela uji dan launcher tetap tertutup.
   Setelah keluar, bingkai kembali dan launcher dapat dibuka lagi. Hasilnya tersimpan lokal di
   `~/.local/state/caelestia-glass/validation-result.txt`.

   Popout baterai dan jaringan diperiksa secara visual dan menampilkan kaca beserta tepinya.
   Variasi lain, termasuk dialog sandi/tray bertingkat, belum diuji lengkap. Sempat ada warning
   model notifikasi `null` saat popup ditutup pada sesi validasi; berkas notifikasi tidak diubah.

   Symlink dan autostart sudah dipasang, lalu fork diluncurkan ulang lewat `caelestia shell -d`
   dengan environment yang sama dengan autostart. Hanya satu instance berjalan melalui konfigurasi
   user; kedua library Blobs yang dimuat berasal dari direktori build fork. Pemeriksaan sintaks Lua
   dan `hyprctl configerrors` lulus. Log peluncuran aktif tidak memiliki error QML/load pada saat dicek.
   Shell kaca dibiarkan aktif. Autostart berikutnya belum diuji dengan reboot/logout.


6. Perbaikan popup menyatu dan kilau Jarvis lembut (`232507f0` pada fork).
   Bingkai dan seluruh latar drawer digambar sekali melalui satu quad dengan satu snapshot SDF.
   Mesh cincin terpisah dihapus agar pembagian piksel tidak meninggalkan celah atau penumpukan
   tint ketika bentuk bergerak. Bentuk tersembunyi tidak lagi ikut menghitung SDF; perubahan
   visibilitas memperbarui grup, sehingga panel tertutup tidak meninggalkan garis pada bingkai.

   Kilau dihitung dari normal kontur gabungan dalam koordinat scene. Tepi 1.2 px memakai sorot
   putih lembut yang memudar 20 px ke dalam kaca, tanpa bercak radial per sudut. Intensitas rim
   0.05–0.24 dan sheen 0.012–0.035; tint surface tetap 0.38 mengikuti warna skema dan acuan Jarvis.
   Bentuk serta fisika gerak panel tetap dipakai sebagai data permukaan gabungan.

   Seluruh 16 kasus render lulus (24 hasil PASS termasuk setup/cleanup), termasuk panel tersembunyi,
   pertemuan beberapa panel, posisi pecahan, kilau pada latar hitam, serta 81 frame buka/tutup pada
   latar hitam dan 81 pada latar putih. Backend terbaru sudah aktif pada desktop.

   Visual: `screenshots/11-unified-animation.webp` memperlihatkan sambungan saat transisi;
   `screenshots/12-soft-white-reflection.png` memperlihatkan kilau akhir pada render hitam.
   Profiling hardware dan batas hasil dicatat di [laporan performa](reports/performance-2026-11-15.md).
   Popup dan multi-panel sekitar 60 FPS; pergantian launcher/dashboard berulang 57.45 FPS dengan
   lonjakan interval hingga 130.43 ms. GPU grafis proses shell sekitar 5.1–11.6% pada skenario aktif.
   Optimasi tile belum diperlukan berdasarkan pengukuran ini; sumber lonjakan launcher/dashboard
   belum diisolasi. Probe profiling tetap di luar repo dan tidak dimuat oleh shell produksi.


7. Modernisasi Rofi Wallpaper Picker (Super+W) & Menu Kaca macOS (2026-11-15).
   Pemilih wallpaper Super+W ternyata dipanggil lewat Rofi (`wppicker.sh`), terpisah dari shell utama.
   Tampilannya dimodernisasi mengikuti estetika liquid glass macOS:

   - Layer blur Hyprland: ditambahkan aturan `namespace = "rofi"` dengan `blur = true`, `ignore_alpha = 0.2`,
     dan animasi `popin 90%` di `~/.config/hypr/hyprland/rules.lua`.
   - Warna kaca: `~/.local/bin/sync-caelestia-rofi.py` secara otomatis mengekspor variabel `glass`
     (surface transparan), `glass-card`, dan `glass-hi` ke `colors.rasi` setiap kali skema diperbarui.
   - Thumbnail squircle presisi: `wppicker.sh` menghasilkan cache thumbnail 480x480 dengan sudut melengkung
     halus lewat ffmpeg, mengisi penuh kartu 240px tanpa menyisakan ruang kosong di atas/bawah. Nama wallpaper
     ditampilkan rapi tanpa ekstensi dan path folder.
   - Layout Spotlight: bilah pencarian berbentuk kapsul (pill) diposisikan di atas grid (`children: [ "inputbar", "listview" ]`),
     kartu wallpaper memakai border putih tipis lembut `rgba(255, 255, 255, 10%)`, dan kartu terpilih disorot
     dengan `glass-hi` serta garis aksen `@primary`.
   - Dialog kategori (`caelestia-menu.rasi`): menu kategori ringkas 440px berlatar kaca dan border melengkung 32px.

   Visual: `screenshots/15-rofi-grid.png` (grid wallpaper kaca) dan `screenshots/16-rofi-category.png` (dialog kategori).


8. Penyempurnaan Shell QML fork & SDDM (`31463924` pada fork).
   - Launcher & Nexus: `WallpaperItem.qml`, `WallItem.qml`, `WallpaperSelect.qml`, dan `WallpaperCategory.qml`
     diselaraskan dengan border seleksi kaca, indikator centang dinamis, penyesuaian kolom grid responsif,
     dan nama berkas yang bersih.
   - Lockscreen: `modules/lock/` (`LockSurface.qml`, `Center.qml`, `Clock.qml`, `PasswordInput.qml`, `ProfilePic.qml`)
     disempurnakan dengan penataan kartu kaca transparan, jam berbobot bersih, dan label pengguna yang rapi.
   - SDDM Login Theme: `sddm/Main.qml` menyelaraskan blur latar belakang dan kartu login dengan gaya Caelestia.

