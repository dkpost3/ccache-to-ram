# ccache-to-ram (tmpfs) --- AOSP Build Workstation Accelerator

Move your `ccache` into RAM (tmpfs) for ultra-fast AOSP builds,\
with automatic synchronization to SSD on boot, shutdown, and via
periodic timer.

------------------------------------------------------------------------

## 🚀 Features

-   ⚡ `ccache` runs from RAM (`tmpfs`) for maximum speed
-   🔄 Automatic restore from SSD on boot
-   💾 Automatic save to SSD on shutdown
-   ⏱ Periodic RAM → SSD backup (every 30 minutes)
-   🧩 systemd integration
-   🛠 Fully configurable size and limits

------------------------------------------------------------------------

## 📂 Repository Structure

    ccache-to-ram/
    ├── scripts/ccache-sync.sh
    ├── systemd/ccache-sync.service
    ├── systemd/ccache-sync-backup.service
    ├── systemd/ccache-sync.timer
    └── profile_snippet.sh

------------------------------------------------------------------------

## ⚙ Default Configuration

  Parameter                      Value
  ------------------------------ --------------------
  tmpfs size (`SIZE`)            64G
  ccache max size (`MAX_SIZE`)   50G
  RAM location                   `/mnt/ccache`
  SSD backup                     `~/.ccache_backup`

------------------------------------------------------------------------

# 📦 Installation

``` bash
# 1) Clone repository
git clone https://github.com/dkpost3/ccache-to-ram.git
cd ccache-to-ram

# 2) Install script
# Option A (recommended): copy
sudo install -m 0755 scripts/ccache-sync.sh /usr/local/bin/ccache-sync.sh

# Option B (auto-update friendly): symlink
# sudo ln -sf "$(pwd)/scripts/ccache-sync.sh" /usr/local/bin/ccache-sync.sh

# 3) Create directories
sudo mkdir -p /mnt/ccache
mkdir -p ~/.ccache_backup

# 4) Add environment variables
cat profile_snippet.sh >> ~/.profile
# Log out/in or:
# source ~/.profile

# 5) Install systemd units
sudo install -m 0644 systemd/ccache-sync.service /etc/systemd/system/
sudo install -m 0644 systemd/ccache-sync-backup.service /etc/systemd/system/
sudo install -m 0644 systemd/ccache-sync.timer /etc/systemd/system/

sudo systemctl daemon-reload

# 6) Enable service and timer
sudo systemctl enable --now ccache-sync.service
sudo systemctl enable --now ccache-sync.timer
```

------------------------------------------------------------------------

# 🔎 Verification

``` bash
mount | grep "/mnt/ccache"
ccache -s
systemctl status ccache-sync.service --no-pager
systemctl list-timers | grep ccache
```

------------------------------------------------------------------------

# 🔧 Updating Configuration

``` bash
sudoedit /usr/local/bin/ccache-sync.sh
sudo systemctl restart ccache-sync.service
ccache -s
```

------------------------------------------------------------------------

# ⬆ Updating From GitHub

``` bash
cd ccache-to-ram
git pull --rebase

# If installed via copy (Option A), reinstall script:
sudo install -m 0755 scripts/ccache-sync.sh /usr/local/bin/ccache-sync.sh

sudo systemctl restart ccache-sync.service
```

------------------------------------------------------------------------

# 🗑 Removal / Rollback

``` bash
sudo systemctl disable --now ccache-sync.timer
sudo systemctl disable --now ccache-sync.service
sudo umount /mnt/ccache || true

sudo rm -f /etc/systemd/system/ccache-sync*.service
sudo rm -f /etc/systemd/system/ccache-sync*.timer

sudo systemctl daemon-reload
```

------------------------------------------------------------------------

# 📝 Notes

-   No `/etc/fstab` entry is required --- mounting is handled by the
    script.
-   In case of sudden power loss, data loss is minimized thanks to
    periodic backups.
-   Recommended `-j` for i7‑12700KF with 64GB RAM: `-j16…18`.
-   Designed primarily for AOSP / Android ROM development environments.

------------------------------------------------------------------------

## 🧠 Why This Matters

For large AOSP trees, moving `ccache` to RAM significantly reduces build
time bottlenecks caused by SSD I/O latency.

If you build ROMs daily --- this makes a real difference.

------------------------------------------------------------------------

**Author:** dkpost3\
**License:** MIT (or specify if different)
