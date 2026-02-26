# ccache RAM Sync Kit (tmpfs) — AOSP build workstation

Этот набор файлов переносит `ccache` в RAM (tmpfs), а также автоматически
синхронизирует кэш на SSD при старте/выключении и по таймеру.

## Состав
- `scripts/ccache-sync.sh` — основной скрипт (монтирует tmpfs, restore/backup, лимиты).
- `systemd/ccache-sync.service` — восстановление при старте и сохранение при остановке.
- `systemd/ccache-sync-backup.service` — ручной/периодический backup RAM→SSD.
- `systemd/ccache-sync.timer` — периодический backup каждые 30 минут.
- `profile_snippet.sh` — фрагмент для `~/.profile` с переменными окружения.

## Параметры по умолчанию
- tmpfs (`SIZE`) = **64G**
- лимит кэша (`MAX_SIZE`) = **50G**
- каталоги: RAM `/mnt/ccache`, SSD-бэкап `~/.ccache_backup`

## Установка (копипаст)
```bash
# 1) распаковать архив
tar -xzf ccache-ram-sync-kit.tar.gz
cd ccache-ram-sync-kit

# 2) установить скрипт
sudo install -m 0755 scripts/ccache-sync.sh /usr/local/bin/ccache-sync.sh

# 3) создать каталоги
sudo mkdir -p /mnt/ccache
mkdir -p ~/.ccache_backup

# 4) переменные окружения (добавить в ~/.profile)
cat profile_snippet.sh >> ~/.profile
# (перелогиниться или source ~/.profile)

# 5) установить systemd unit'ы
sudo install -m 0644 systemd/ccache-sync.service /etc/systemd/system/ccache-sync.service
sudo install -m 0644 systemd/ccache-sync-backup.service /etc/systemd/system/ccache-sync-backup.service
sudo install -m 0644 systemd/ccache-sync.timer /etc/systemd/system/ccache-sync.timer
sudo systemctl daemon-reload

# 6) включить сервис и таймер
sudo systemctl enable --now ccache-sync.service
sudo systemctl enable --now ccache-sync.timer
```

## Проверка
```bash
mount | grep "on /mnt/ccache type tmpfs"
ccache -s
systemctl status ccache-sync.service --no-pager
systemctl list-timers | grep ccache
```

## Обновление настроек (например, USER_NAME, SIZE, MAX_SIZE)
```bash
sudoedit /usr/local/bin/ccache-sync.sh     # или sudo nano ...
sudo systemctl restart ccache-sync.service
ccache -s
```

## Удаление / откат
```bash
sudo systemctl disable --now ccache-sync.timer
sudo systemctl disable --now ccache-sync.service
sudo umount /mnt/ccache || true
sudo rm -f /etc/systemd/system/ccache-sync*.service /etc/systemd/system/ccache-sync*.timer
sudo systemctl daemon-reload
```

## Примечания
- В `/etc/fstab` **не** нужно добавлять tmpfs для `/mnt/ccache` — этим занимается скрипт.
- Если питание пропадёт внезапно, потери минимальны благодаря периодическому backup (таймер).
- Оптимальный `-j` для i7‑12700KF с 64ГБ RAM: `-j16…18`.
