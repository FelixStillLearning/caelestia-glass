# Installing Caelestia Glass

This guide assumes an existing Hyprland and Caelestia installation. Review and back up configuration files before replacing them.

## Dependencies

Install Hyprland, Quickshell, Caelestia CLI, CMake, Ninja, a C++ compiler, Rofi with Wayland support, FFmpeg, Python, and Pillow. The development environment used Hyprland 0.57 and Qt 6.12; older versions have not been verified.

For the build and wallpaper tools on Arch Linux:

```bash
sudo pacman -S cmake ninja gcc rofi-wayland ffmpeg python python-pillow
```

This command does not install the full desktop environment. Install compatible Hyprland, Quickshell, and Caelestia packages separately. Obtain SF Pro and Material Symbols Rounded fonts separately under their respective licenses.

## Build the shell fork

```bash
mkdir -p "$HOME/.local/src"
git clone -b glass https://github.com/FelixStillLearning/caelestia-shell.git "$HOME/.local/src/caelestia-shell"
cd "$HOME/.local/src/caelestia-shell"
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DENABLE_MODULES=plugin
cmake --build build
```

Back up or move any existing `~/.config/quickshell/caelestia` directory or symlink before creating the link:

```bash
mkdir -p "$HOME/.config/quickshell"
ln -s "$HOME/.local/src/caelestia-shell" "$HOME/.config/quickshell/caelestia"
```

Alternatively, after cloning the fork, run `./setup.sh` from this repository. The helper builds the fork, creates the configuration link, runs an existing Rofi color synchronizer if available, and requests a Hyprland reload. It does not install packages or configure autostart.

## Configure autostart

For a Caelestia Lua configuration in `~/.config/hypr/hyprland/execs.lua`, adjust the existing shell command:

```lua
hl.exec_once("env QML_IMPORT_PATH=" .. os.getenv("HOME") .. "/.local/src/caelestia-shell/build/qml caelestia shell -d")
```

For a standard `hyprland.conf`:

```ini
exec-once = env QML_IMPORT_PATH=$HOME/.local/src/caelestia-shell/build/qml caelestia shell -d
```

## Compositor rules

The glass material requires compositor blur. Review the matching rules in the [dotfiles repository](https://github.com/FelixStillLearning/caelestia-hypr-backup/blob/main/hypr/hyprland/rules.lua) for the Hyprland version you use. Do not replace your entire rules file.

The Rofi rule used by the Lua configuration is:

```lua
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0.2, animation = "popin 90%" })
```

The shell uses the `caelestia-(drawers|background)` namespaces. Preserve the existing shell blur and animation rules when merging configuration. Reload after editing:

```bash
hyprctl reload
```

## Rofi wallpaper picker

The following files are available in the [dotfiles repository](https://github.com/FelixStillLearning/caelestia-hypr-backup):

- `rofi/wallpaper-picker.rasi` and `rofi/caelestia-menu.rasi`: copy to `~/.config/rofi/`.
- `hypr/scripts/wppicker.sh`: copy to the same path under `~/.config/`.
- `local-bin/sync-caelestia-rofi.py`: copy to `~/.local/bin/`.

Review script dependencies and wallpaper directory settings before use. Mark the scripts executable, run the color synchronizer to generate `~/.config/rofi/colors.rasi`, and bind the picker:

```bash
chmod +x "$HOME/.config/hypr/scripts/wppicker.sh" "$HOME/.local/bin/sync-caelestia-rofi.py"
python3 "$HOME/.local/bin/sync-caelestia-rofi.py"
```

```lua
hl.bind("SUPER + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/wppicker.sh"))
```

## Restart and recovery

The lockscreen runs inside the shell. Before stopping it, check its state and continue only if it reports `false`:

```bash
qs -c caelestia ipc call lock isLocked
```

Once unlocked, stop the existing instance and start the fork with its compiled plugin path:

```bash
qs -c caelestia kill
env QML_IMPORT_PATH="$HOME/.local/src/caelestia-shell/build/qml" caelestia shell -d
```

To return to the packaged shell, stop the fork while unlocked, remove only the configuration symlink, restore your previous autostart command and configuration, and run `caelestia shell -d`.

## SDDM

`sddm/Main.qml` is an adapted main view. It references components, widgets, and assets from the existing Caelestia SDDM theme. It is not a complete theme package and is not installed by `setup.sh`. Back up the existing theme before any manual integration.
