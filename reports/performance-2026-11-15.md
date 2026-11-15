# Profil performa kaca — 2026-11-15

Popup bergerak dan beberapa panel sekaligus mencapai sekitar 60 FPS pada layar 60 Hz.
Beban engine grafis proses shell sekitar 5.1–11.6% pada kedua skenario tersebut. Pergantian
launcher/dashboard berulang mencapai 57.45 FPS dan memiliki lonjakan interval frame.
Hasil ini tidak menunjukkan perlunya mengembalikan mesh terpisah atau menambah optimasi tile.

## Perangkat dan metode

- Sumber yang diukur: fork lokal `caelestia-shell`, commit `232507f09bda2f54cb4c114965266f14fba9066a`.
- Ryzen AI 7 350, Radeon 860M; layar eDP-1 1920×1200, 60.003 Hz, skala 1.
- Qt 6.12.0, threaded render loop, OpenGL 4.6, amdgpu/radeonsi Mesa 26.2.6; kernel 7.2.14-arch1-1.
- Laptop memakai baterai dan kebijakan clock GPU `auto`; aplikasi lain tetap berjalan.
- Salinan konfigurasi shell dengan sumber/plugin yang sama diberi probe sementara di luar repo.
  Probe memakai `QQuickWindow.frameSwapped` dan `ElapsedTimer` untuk interval frame.
  Skenario aktif meminta redraw setiap `FrameAnimation` agar ada beban animasi berkelanjutan.
- Setiap skenario dipanaskan 2 detik, lalu diukur sekitar 8 detik. Counter GPU/CPU disampel
  setiap 200 ms. Tidak ada pengambilan screenshot atau perekaman video selama pengukuran.
- Waktu engine GPU berasal dari `/proc/PID/fdinfo`; FD dengan perangkat dan client-id yang sama
  dihitung sekali. Counter yang sementara menurun ditahan pada nilai tertinggi sebelumnya.
  CPU dinyatakan sebagai persentase satu logical core, RSS adalah memori proses.

Metode mengikuti dokumentasi [frameSwapped Qt](https://doc.qt.io/qt-6/qquickwindow.html#frameSwapped),
[FrameAnimation](https://doc.qt.io/qt-6/qml-qtquick-frameanimation.html), dan
[counter DRM Linux](https://docs.kernel.org/gpu/drm-usage-stats.html).

## Hasil

| Skenario | FPS Qt | p95 ms | p99 ms | GPU gfx shell | CPU satu core | RSS MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Baseline tanpa redraw paksa | — | — | — | 0.95% | 3.09% | 773 |
| Popup berganti dan bergerak | 59.98 | 18.67 | 22.17 | 5.11% | 14.94% | 812 |
| Launcher/dashboard bergantian | 57.45 | 19.21 | 112.05 | 6.55% | 34.40% | 1068 |
| Dashboard + sidebar/utilities + popup | 59.95 | 18.46 | 20.54 | 11.63% | 29.55% | 1032 |

Baseline tidak memakai redraw berkelanjutan sehingga tidak diberi target FPS atau percentile pacing.
Engine compute rata-rata di bawah 0.16% pada seluruh skenario. Rata-rata GPU seluruh perangkat
adalah 12.1%, 36.2%, 36.9%, dan 43.8% sesuai urutan tabel; angka itu juga mencakup compositor
serta aplikasi lain, sehingga tidak boleh seluruhnya diatribusikan ke shell.

## Batas hasil dan tindak lanjut

- Pada pergantian launcher/dashboard ada 12 dari 467 interval di atas 1.5× anggaran refresh
  (sekitar 25 ms), dengan interval maksimum 130.43 ms. Skenario popup memiliki 1 dari 487;
  multi-panel tidak memiliki interval di atas ambang tersebut.
- Aktivitas GPU shell pada skenario launcher/dashboard hanya 6.55%. Beban pemuatan/layout GUI
  merupakan dugaan untuk ditelusuri lebih lanjut; profiling ini belum mengisolasi fungsi penyebab.
  Loader dashboard/launcher tidak diubah sebagai bagian perbaikan material.
- FPS dan percentile berasal dari callback Qt yang diterima GUI thread, bukan timestamp present
  hardware compositor; penjadwalan thread dapat memengaruhi interval yang terukur.
- Ini pengukuran singkat pada satu perangkat/refresh rate. Belum mencakup uji baterai jangka panjang,
  layar resolusi/skala lain, atau pengukuran GPU timestamp per draw call.
- Probe dan runner disimpan lokal di `~/.local/state/caelestia-glass/profile/`.
  Jalankan ulang dengan `python ~/.local/state/caelestia-glass/profile/run_profile.py` ketika sesi
  tidak terkunci; runner mengaktifkan shell uji sementara dan memulihkan fork normal setelahnya.
  Probe tidak ditambahkan ke shell produksi.

Data interval dan sampel mentah: [performance-2026-11-15.json](performance-2026-11-15.json).
Shell normal dipulihkan setelah pengukuran dan hanya satu instance fork dibiarkan aktif.
