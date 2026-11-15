# Development log

Caelestia Glass explores a macOS-inspired translucent material. The `reference/` directory contains the source used for visual comparison.

## Reference and scope

The intended treatment combines background blur, thin translucent tint, a soft white outline, inward sheen, concave screen-edge joins, spring motion, and wallpaper-derived colors. The design reference uses layered Qt Quick shapes and outlines. The shell implementation uses a shared C++ SDF renderer, so the current appearance is an approximation rather than a verified visual match.

## Environment and activation

Development used Caelestia Shell 2.5.0, Hyprland 0.57 with Lua configuration, and Qt 6.12. The packaged shell remained in `/etc/xdg/quickshell/caelestia`; the fork was built separately on its `glass` branch.

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DENABLE_MODULES=plugin
cmake --build build
```

The runtime configuration links `~/.config/quickshell/caelestia` to the fork in `~/.local/src/caelestia-shell`. Autostart must include the compiled QML plugin path:

```bash
env QML_IMPORT_PATH="$HOME/.local/src/caelestia-shell/build/qml" caelestia shell -d
```

Check `qs -c caelestia ipc call lock isLocked` before stopping or restarting the shell. Continue only when the result is `false`. Activation changes were confined to user configuration; system packages were retained.

## Implementation history

### OSD prototype and outer shadows

The first OSD prototype introduced a bright 1.2 px rim and corner sheen. A `MultiEffect` shadow overlapped the translucent surface, raising measured alpha to approximately 0.44 instead of the intended 0.38 and leaving a dark band near the frame.

The replacement computes shadow falloff from the combined SDF and clips it to the outside of the geometry. This prevents the shadow from increasing surface tint. The shadow is limited to 15 px or the smaller smoothing padding, follows the color scheme, and fades during fullscreen transitions.

An isolated render measured OSD tint at 97/255, approximately 0.38. Render tests cover tint, panel/frame joins, exterior shadows, unchanged interior pixels, and transparent shadow colors. The old shader failed the same tint check.

### Screen frame and bar

Frame glass initially reused the OSD material through `BlobInvertedRect.glass`. Tests covered the bar, frame, panel joins, outer shadow, mesh transitions, and disabled glass at base alpha values of 1 and 0.8. Builds and the corresponding render tests passed during development.

### Shared panel glass

Moving the binding to the shared `PanelBg` applied the material to the dashboard, launcher, session panel, sidebar, notifications, utilities, and popouts. Content cards, controls, and critical notification indicators retained their existing colors.

Contributions from nearby panels are normalized to maintain a single tint where two or three glass shapes meet. Sidebar and utility shapes excluded from contour blending still participate in pixel ownership, preventing overlapping surfaces from being drawn twice.

Tests initially failed with the previous shader and then passed for two-panel joins, base alpha 0.8, three overlapping panels, and excluded panels. Desktop checks exercised the main drawers and a synthetic local notification.

### Unified rendering and sheen

The frame and drawer backgrounds now render once through a single quad and one SDF snapshot. The separate ring mesh was removed to avoid gaps and duplicated tint during motion. Hidden shapes no longer affect the SDF, and visibility changes update the group.

Contour normals in scene coordinates control a soft directional white rim and inward sheen. The recorded parameters are a 1.2 px rim, a 20 px inward fade, rim intensity 0.05–0.24, sheen intensity 0.012–0.035, and surface tint alpha 0.38. These values describe the current approximation; they do not establish parity with the layered reference.

Development validation recorded 16 render cases passing, or 24 PASS results including setup and cleanup. Coverage included hidden panels, panel intersections, fractional positions, sheen on black backgrounds, and 81 opening/closing frames on each of black and white backgrounds.

Run the fork's render tests with an active display:

```bash
QML_IMPORT_PATH="$PWD/build/qml" QSG_RHI_BACKEND=opengl /usr/lib/qt6/bin/qmltestrunner -input tests
```

### Desktop activation checks

A temporary Qt window was moved into and out of fullscreen. Five sampled screen-edge pixels matched the test window while fullscreen; after leaving fullscreen, the frame returned and the launcher opened again.

Battery and network popouts were checked visually. One notification model `null` warning appeared during a validation run. The active shell subsequently loaded the fork's two Blobs libraries without QML/plugin loading errors at the time checked. Lua syntax and `hyprctl configerrors` checks passed.

Logout/reboot autostart, all nested tray/password popouts, and every display configuration were not verified.

### Rofi wallpaper picker

The Super+W picker is a separate Rofi process. Its compositor rule enables blur for the `rofi` namespace with `ignore_alpha = 0.2` and `popin 90%` animation. The color synchronizer exports translucent `glass`, `glass-card`, and `glass-hi` colors from the active palette.

The picker generates rounded 480×480 thumbnails through FFmpeg for 240 px cards. Square thumbnails fill Rofi's square icon allocation; plain 16:9 thumbnails previously left vertical space. Labels omit folders and extensions. The search field sits above the grid, with a subtle white card border and palette-derived selection accent. A separate 440 px category menu theme is also available; the current picker opens the wallpaper grid directly.

### QML and SDDM

Launcher and Nexus wallpaper items received selection borders, check indicators, adjusted grid sizing, and cleaned labels. Lockscreen changes align the clock, transparent password input, profile presentation, and surrounding glass surfaces. The supplied SDDM main view depends on the existing theme's components and assets.

## Performance

The [performance report](../reports/performance-2026-11-15.md) records the method, hardware, results, and limits. Popup and multi-panel scenarios reached approximately 60 FPS; repeated launcher/dashboard switching reached 57.45 FPS with intervals up to 130.43 ms. Shell graphics engine utilization was approximately 5.1–11.6% in active scenarios.

The measurement did not establish a need for tile optimization. The cause of launcher/dashboard frame interval spikes remains unisolated. Temporary measurement probes stayed outside the production fork.

## Glass lighting update

The shared shader now uses the design reference's horizontal rim profile, with peaks of 0.55 and 0.40. A lower-surface gradient reaches white opacity 0.07, while two localized lower-corner highlights use opacity 0.13 and 0.09 with a 46 px radius. Panel coordinates follow the existing deformation matrix. Frame lighting remains contour based because its geometry surrounds the screen rather than forming a solid panel.

Lighting is composited once over the shared surface. Highlights from corners buried inside another surface are suppressed, and material contributions are normalized to avoid stacking at panel intersections. Disabling glass retains the original material.

The new render tests reproduce the missing bottom glow, corner highlights, and rim contrast with the previous shader, then pass with the updated shader. The full render suite passes: 20 test cases, or 30 PASS results including setup and cleanup. Qt Wayland text-input focus warnings appear between test windows; no test fails. The plugin was rebuilt and loaded into the active shell while unlocked.

New documentation previews show the actual bar/frame, OSD, and utilities on an isolated workspace with a demonstration image viewer. Notifications were suppressed temporarily, and the original workspace and notification setting were restored after capture. The earlier performance measurements predate this lighting update; performance has not been measured again.

## Material roles, light/dark appearance, and depth

The material treatment follows the applicable hierarchy and legibility guidance in Apple's [Materials HIG](https://developer.apple.com/design/human-interface-guidelines/materials) and the visual principles in [Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/). This is a Qt/Hyprland approximation using compositor blur and SDF lighting; it does not implement Apple's native backdrop lensing or vibrancy engine.

Connected functional surfaces use a regular tint of 0.7 so text remains legible over bright and dark content. They share one material through their joins. Existing content cards retain their standard materials. The lower-tint shader path remains available for thin glass. Turning transparency off disables both glass variants and restores opaque toast backgrounds, borders, and the existing elevation treatment.

The active-window label and clock use the semantic surface foreground while glass is enabled. Toasts use neutral glass and surface text colors; success, warning, and error indicators retain their colored icon badges. Secondary toast text uses 0.9 opacity to preserve contrast on white.

Cast shadows retain their existing 15 px reach and base strength. Dark surfaces keep a downward/right bias, while light surfaces cast a soft shadow below. Dark glass frames suppress the inner cast shadow; light frames retain a faint contact shadow. Toast contact shadows are slightly stronger in the light appearance. These directions are implementation choices, not fixed light-source rules prescribed by Apple. Rim and local highlights remain separate from cast shadows.

Light glass also has an approximately 1 px optical contour inside its outer edge, so both sides remain visible over white without adding a surrounding shadow. The contour follows the merged geometry, avoids internal joins, and leaves the glass body, dark appearance, and opaque material unchanged. Regular glass remains translucent with a 0.7 tint; a plain white background naturally reveals less transmission than a detailed image.

Validation covers the actual light and dark theme settings over white and dark backgrounds, all four toast types, and the opaque fallback when transparency is disabled. Measured title contrast across the toast matrix was at least 5.65:1, with secondary text at least 4.94:1. Render tests cover regular-material contrast, material joins, directional shadows, bounded light-frame contact shadows, and disabled glass. Two additional regression cases check visible left/right contours over white for regular and thin glass, no surrounding halo, and unchanged body pixels; both failed before the contour change. All five render suites pass separately, reporting 40 PASS results including setup and cleanup, with no failures. Qt Wayland text-input focus warnings still appear between test windows.

See the [light-on-white frame check](images/light-white-frame.png) and the reviewed light/dark previews in the [README](../README.md#preview). The original theme, transparency setting, notification setting, and workspace are restored after checks. Performance measurements earlier in this log predate these material changes and were not repeated.

## Thin exterior lines during panel opening

The shader's rectangular distance cull replaced distant shapes with a large sentinel. That discontinuity inflated the distance derivatives used for antialiasing, creating thin horizontal or vertical lines beyond moving panels. Rectangle distances now remain continuous across the frame; the glass material and real panel edges are unchanged.

Regression checks reproduce the old artifact at fractional panel positions over black and white backgrounds in both appearances. The complete render suite now reports 44 PASS results, including setup and cleanup, with no failures. Weather and utilities panels were also checked in the active shell on an isolated workspace. The reviewed utilities previews were refreshed.

Removing the distance cull increases shader work. A short 8.1-second multi-panel check reached 59.80 FPS, with a 17.99 ms p95 frame interval and 19.60% shell graphics engine utilization on the same device used for the earlier profile. This is a spot check, not a controlled before/after comparison or a battery measurement.

## Public assets and privacy

Local desktop captures were removed from the project and its rewritten Git history because they exposed private notifications and application content. The screenshot directory is ignored. Any future showcase images must be reviewed in full, including backgrounds visible through transparent surfaces.
