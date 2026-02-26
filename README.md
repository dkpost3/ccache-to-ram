# ccache RAM Sync Kit (tmpfs) --- AOSP build workstation

This file set moves `ccache` into RAM (tmpfs) and automatically
synchronizes the cache to SSD on startup/shutdown and periodically via
timer.

## Contents

-   `scripts/ccache-sync.sh` --- main script (mounts tmpfs,
    restore/backup, limits).
-   `systemd/ccache-sync.service` --- restore on boot and save on
    shutdown.
-   `systemd/ccache-sync-backup.service` --- manual/periodic RAM→SSD
    backup.
-   `systemd/ccache-sync.timer` --- periodic backup every 30 minutes.
-   `profile_snippet.sh` --- snippet for `~/.profile` with environment
    variables.

## Default Parameters

-   tmpfs (`SIZE`) = **64G**
-   cache limit (`MAX_SIZE`) = **50G**
-   directories: RAM `/mnt/ccache`, SSD backup `~/.ccache_backup`

## Installation (copy-paste)

``` bash
# 1) extract the archive
tar -xzf ccache-ram-sync-kit.tar.gz
cd ccache-ram-sync-kit

# 2) install the script
sudo install -m 0755 scripts/ccache-sync.sh /usr/local/bin/ccache-sync.sh

# 3) create directories
sudo mkdir -p /mnt/ccache
mkdir -p ~/.ccache_backup

# 4) environment variables (append to ~/.profile)
cat profile_snippet.sh >> ~/.profile
# (log out/in or source ~/.profile)

# 5) install systemd units
sudo install -m 0644 systemd/ccache-sync.service /etc/systemd/system/ccache-sync.service
sudo install -m 0644 systemd/ccache-sync-backup.service /etc/systemd/system/ccache-sync-backup.service
sudo install -m 0644 systemd/ccache-sync.timer /etc/systemd/system/ccache-sync.timer
sudo systemctl daemon-reload

# 6) enable service and timer
sudo systemctl enable --now ccache-sync.service
sudo systemctl enable --now ccache-sync.timer
```

## Verification

``` bash
mount | grep "on /mnt/ccache type tmpfs"
ccache -s
systemctl status ccache-sync.service --no-pager
systemctl list-timers | grep ccache
```

## Updating Settings (e.g., USER_NAME, SIZE, MAX_SIZE)

``` bash
sudoedit /usr/local/bin/ccache-sync.sh     # or sudo nano ...
sudo systemctl restart ccache-sync.service
ccache -s
```

## Removal / Rollback

``` bash
sudo systemctl disable --now ccache-sync.timer
sudo systemctl disable --now ccache-sync.service
sudo umount /mnt/ccache || true
sudo rm -f /etc/systemd/system/ccache-sync*.service /etc/systemd/system/ccache-sync*.timer
sudo systemctl daemon-reload
```

## Notes

-   You do **not** need to add a tmpfs entry for `/mnt/ccache` in
    `/etc/fstab` --- the script handles it.
-   If power is lost unexpectedly, data loss is minimal thanks to
    periodic backup (timer).
-   Optimal `-j` for i7-12700KF with 64GB RAM: `-j16…18`.
