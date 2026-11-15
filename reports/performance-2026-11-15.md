# Glass performance profile — 2026-11-15

Moving popups and simultaneous panels reached approximately 60 FPS on a 60 Hz display. Shell graphics engine utilization was approximately 5.1–11.6% in those scenarios. Repeated launcher/dashboard switching reached 57.45 FPS with frame interval spikes. These measurements did not indicate a need to restore separate meshes or add tile optimization.

## Hardware and method

- Measured source: local `caelestia-shell` fork, commit `232507f09bda2f54cb4c114965266f14fba9066a`.
- Ryzen AI 7 350, Radeon 860M; eDP-1 display at 1920×1200, 60.003 Hz, scale 1.
- Qt 6.12.0, threaded render loop, OpenGL 4.6, amdgpu/radeonsi Mesa 26.2.6; kernel 7.2.14-arch1-1.
- The laptop ran on battery with GPU clock policy `auto`; other applications remained running.
- A temporary configuration outside the repository used the same shell source and plugin with a `QQuickWindow.frameSwapped` and `ElapsedTimer` probe. Active scenarios requested redraws through `FrameAnimation` to maintain animation load.
- Each scenario warmed up for 2 seconds and ran for approximately 8 seconds. GPU/CPU counters were sampled every 200 ms. No screenshot or screen recording ran during measurement.
- GPU engine time came from `/proc/PID/fdinfo`. File descriptors sharing the same device and client ID were counted once. Temporarily decreasing counters were held at their previous high-water marks. CPU percentages refer to one logical core; RSS measures process memory.

Method references: Qt [frameSwapped](https://doc.qt.io/qt-6/qquickwindow.html#frameSwapped), [FrameAnimation](https://doc.qt.io/qt-6/qml-qtquick-frameanimation.html), and Linux [DRM usage statistics](https://docs.kernel.org/gpu/drm-usage-stats.html).

## Results

| Scenario | Qt FPS | p95 ms | p99 ms | Shell GPU gfx | CPU, one core | RSS MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Baseline without forced redraw | — | — | — | 0.95% | 3.09% | 773 |
| Switching and moving popups | 59.98 | 18.67 | 22.17 | 5.11% | 14.94% | 812 |
| Alternating launcher/dashboard | 57.45 | 19.21 | 112.05 | 6.55% | 34.40% | 1068 |
| Dashboard + sidebar/utilities + popup | 59.95 | 18.46 | 20.54 | 11.63% | 29.55% | 1032 |

The baseline did not continuously redraw, so FPS targets and frame pacing percentiles are omitted. Average compute engine usage stayed below 0.16% in every scenario. Average device-wide GPU utilization was 12.1%, 36.2%, 36.9%, and 43.8%, respectively. Those totals also include the compositor and other applications and cannot be attributed entirely to the shell.

## Limits and follow-up

- Launcher/dashboard switching produced 12 of 467 intervals above 1.5× the refresh budget, approximately 25 ms, with a maximum of 130.43 ms. The popup scenario had 1 of 487; the multi-panel scenario had none above this threshold.
- Shell GPU activity during launcher/dashboard switching was only 6.55%. GUI loading or layout work is a hypothesis for further investigation; this profile did not isolate the responsible function. The dashboard/launcher loaders were not changed for the material work.
- FPS and percentiles use Qt callbacks delivered to the GUI thread, rather than hardware compositor presentation timestamps. Thread scheduling can affect the measured intervals.
- This was a short measurement on one device and refresh rate. Long battery tests, other resolutions/scales, and per-draw GPU timestamps were not covered.
- The probe and runner remain local in `~/.local/state/caelestia-glass/profile/`. The runner temporarily starts a test shell and restores the normal fork. Run it only when the session is unlocked. The probe is not part of the production shell.

Raw intervals and samples: [performance-2026-11-15.json](performance-2026-11-15.json). The normal shell was restored after measurement, leaving one active fork instance.
