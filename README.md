# plymouth-rpi-spinner

Plymouth theme and helper for Raspberry Pi spinner splash screens. This project bundles a ready-to-use Plymouth theme (`rpi-spinner`) with image frames and a small activation script. The theme is intended for Raspberry Pi kiosk and embedded images where a simple spinner splash is desired during boot/login.

---

## 📦 Features

- A complete Plymouth theme (`rpi-spinner`) with multiple frame PNGs for smooth spinner animation
- Activation/deactivation helper script: `src/plymouth-rpi-spinner.sh` (activate sets theme and rebuilds initramfs)
- Theme files organized under `src/rpi-spinner/` for easy customization

---

## 🧰 Dependencies

Required on the host or target system:

- `bash`
- `plymouth`, `plymouth-themes`
- `update-initramfs` (used by `plymouth-set-default-theme -R` to rebuild initramfs)

These are standard packages on Debian/Raspbian systems.

---

## 📂 Installation

### Install via `.deb`

Build or download the release package and install it on the device:

```bash
wget https://github.com/aragon25/plymouth-rpi-spinner/releases/download/v1.2-1/plymouth-theme-rpi-spinner_1.2-1_all.deb
sudo apt install ./plymouth-theme-rpi-spinner_1.2-1_all.deb
```

This installs the theme into `/usr/share/plymouth/themes/rpi-spinner` and places the activation script in `/usr/local/bin/` (packaging may vary; inspect `deploy/config/build_deb.conf`).

---

## ⚙️ Usage

Use the included helper script or `plymouth-set-default-theme` directly. The helper performs basic checks and sets the theme for you.

Activate theme (recommended):

```bash
sudo plymouth-rpi-spinner --activate
```

Deactivate (revert to default `details` theme):

```bash
sudo plymouth-rpi-spinner --deactivate
```

Alternatively, set theme and rebuild initramfs manually:

```bash
sudo plymouth-set-default-theme -R rpi-spinner
```

Verify current theme:

```bash
plymouth-set-default-theme
```

Notes:
- The `-R` flag to `plymouth-set-default-theme` rebuilds initramfs so the theme appears during early boot.
- After activating, reboot to see the splash during initramfs/kernel handover.

---

## 📁 Files of interest

- `src/plymouth-rpi-spinner.sh` — activation/deactivation helper script (entrypoint).
- `src/rpi-spinner/` — theme resources: `rpi-spinner.plymouth`, `rpi-spinner.script`, many `LOGINSPINNER-*.PNG` frames and preview images.
- `src/plymouth-wait.conf` — optional plymouth wait config used by theme or packaging.
- `deploy/build_test_deb.sh`, `deploy/build_deb.sh` — packaging helpers that produce `.deb` in `packages/`.
- `deploy/config/build_deb.conf` — packaging configuration and hook references.

---

## ⚠️ Safety & recommendations

- Activating the theme rebuilds initramfs — test on a spare device or VM before deploying at scale.
- Inspect packaging hooks (`deploy/config/preinst.sh`, `postinst.sh`, etc.) before installing packages on production systems.
- Keep the number and size of PNG frames reasonable to avoid large initramfs images; prefer compressed PNGs with sensible dimensions.
