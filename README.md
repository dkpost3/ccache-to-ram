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

mount | grep "/mnt/ccache"
ccache -s
systemctl status ccache-sync.service --no-pager
systemctl list-timers | grep ccache

sudoedit /usr/local/bin/ccache-sync.sh
sudo systemctl restart ccache-sync.service
ccache -s

sudo systemctl disable --now ccache-sync.timer
sudo systemctl disable --now ccache-sync.service
sudo umount /mnt/ccache || true

sudo rm -f /etc/systemd/system/ccache-sync*.service
sudo rm -f /etc/systemd/system/ccache-sync*.timer

sudo systemctl daemon-reload
```
