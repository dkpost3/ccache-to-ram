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

## 🖥 System Requirements

This setup reserves RAM permanently for tmpfs.\
Make sure your system has enough memory for both:

1.  AOSP build process
2.  ccache tmpfs allocation

------------------------------------------------------------------------

### 📐 Engineering RAM Sizing Formula

To size your system properly:

    Total_RAM ≥ tmpfs_SIZE + build_peak + safety_margin

Where:

-   `tmpfs_SIZE` --- RAM allocated for ccache (e.g. 25G / 50G)
-   `build_peak` --- peak RAM usage during AOSP build
-   `safety_margin` --- recommended 20% of total RAM

------------------------------------------------------------------------

### Typical AOSP Build Peak Usage

  Build Type                   -j   Peak RAM Usage
  ---------------------------- ---- ----------------
  Minimal tree                 12   18--24 GB
  Full AOSP + GMS              16   24--36 GB
  Full tree + heavy parallel   20   32--40 GB

------------------------------------------------------------------------

### Practical Examples

#### Example 1 --- 25G tmpfs

    25G (ccache)
    + 30G (build peak)
    + ~10G (safety margin)
    = ~65G recommended total RAM

→ **Recommended system RAM: 64 GB**

------------------------------------------------------------------------

#### Example 2 --- 50G tmpfs

    50G (ccache)
    + 35G (build peak)
    + ~15G (safety margin)
    = ~100G recommended total RAM

→ **Recommended system RAM: 96--128 GB**

------------------------------------------------------------------------

### Recommended RAM by Configuration

  tmpfs SIZE   Recommended Total RAM   Suitable For
  ------------ ----------------------- ----------------------------
  25G          64 GB                   Daily ROM builds
  50G          96 GB                   Heavy parallel AOSP builds
  64G          128 GB                  Dedicated build server

------------------------------------------------------------------------

### ⚠ Important Notes

-   Do NOT allocate 50G tmpfs on a 32 GB system.
-   Swapping completely destroys build performance.
-   Monitor usage with:

``` bash
free -h
htop
```

-   If system starts swapping → reduce `SIZE` immediately.

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
git clone https://github.com/dkpost3/ccache-to-ram.git
cd ccache-to-ram

sudo install -m 0755 scripts/ccache-sync.sh /usr/local/bin/ccache-sync.sh

sudo mkdir -p /mnt/ccache
mkdir -p ~/.ccache_backup

cat profile_snippet.sh >> ~/.profile

sudo install -m 0644 systemd/ccache-sync.service /etc/systemd/system/
sudo install -m 0644 systemd/ccache-sync-backup.service /etc/systemd/system/
sudo install -m 0644 systemd/ccache-sync.timer /etc/systemd/system/

sudo systemctl daemon-reload
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

## 🧠 Why This Matters

For large AOSP trees, moving `ccache` to RAM significantly reduces build
time bottlenecks caused by SSD I/O latency.

If you build ROMs daily --- this makes a real difference.
