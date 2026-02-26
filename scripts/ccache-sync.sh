#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${CCACHE_USER:-${SUDO_USER:-$(logname 2>/dev/null || echo ${USER:-user})}}"  # можно переопределить CCACHE_USER
RAM_DIR="/mnt/ccache"
BK_DIR="/home/${USER_NAME}/.ccache_backup"
SIZE="64G"                           # объём tmpfs (под 50G кэша оставляем запас)
MAX_SIZE="50G"                       # целевой лимит ccache (<= SIZE с запасом)

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "[ccache-sync] '$1' not found"; exit 1; }; }

preflight() {
  need_cmd rsync
  need_cmd ccache
  # каталоги и права
  install -d -m 1777 "$RAM_DIR"
  install -d -m 0700 "$BK_DIR"
  # вычистим странные ACL/immutable, если вдруг были
  setfacl -b "$BK_DIR" 2>/dev/null || true
  sudo chattr -R -i "$BK_DIR" 2>/dev/null || true
}

mount_tmpfs() {
  if ! mountpoint -q "$RAM_DIR"; then
    echo "[ccache-sync] Mounting tmpfs ($SIZE) to $RAM_DIR"
    sudo mount -t tmpfs -o size=$SIZE,noatime,mode=1777 tmpfs "$RAM_DIR"
  fi
}

apply_ccache_limits() {
  # локальный конфиг в каталоге кэша — чтобы лимит сохранялся
  printf "max_size = %s\n" "$MAX_SIZE" > "$1/ccache.conf"
  CCACHE_DIR="$1" sudo -u "$USER_NAME" ccache -M "$MAX_SIZE"
}

restore() {
  preflight
  mount_tmpfs
  if [ -d "$BK_DIR" ] && [ -n "$(ls -A "$BK_DIR" 2>/dev/null || true)" ]; then
    echo "[ccache-sync] Restoring backup → RAM"
    rsync -rltH --no-o --no-g --delete           --chmod=Du+rwx,Dgo-rwx,Fu+rw,Fgo-rwx           "$BK_DIR/" "$RAM_DIR/"
  fi
  chown -R "$USER_NAME:$USER_NAME" "$RAM_DIR"
  apply_ccache_limits "$RAM_DIR"
  CCACHE_DIR="$RAM_DIR" sudo -u "$USER_NAME" ccache -c || true
}

backup() {
  if mountpoint -q "$RAM_DIR"; then
    echo "[ccache-sync] Cleaning cache before backup"
    apply_ccache_limits "$RAM_DIR"
    CCACHE_DIR="$RAM_DIR" sudo -u "$USER_NAME" ccache -c || true

    echo "[ccache-sync] Backing up RAM → SSD"
    rsync -rltH --no-o --no-g --delete           --chmod=Du+rwx,Dgo-rwx,Fu+rw,Fgo-rwx           "$RAM_DIR/" "$BK_DIR/"
    chown -R "$USER_NAME:$USER_NAME" "$BK_DIR"
  fi
}

case "${1:-}" in
  start)   restore ;;
  stop)    backup ;;
  restart) backup && restore ;;
  *)       echo "Usage: $0 {start|stop|restart}" ; exit 2 ;;
esac
