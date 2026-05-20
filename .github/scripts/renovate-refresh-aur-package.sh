#!/usr/bin/env bash
set -euo pipefail

pkgdir="${1:?package directory required}"

case "$pkgdir" in
  /*|*..*|*' '*|'')
    echo "Unsupported package directory: $pkgdir" >&2
    exit 2
    ;;
esac

docker run --rm \
  -v "$PWD":/repo \
  -w "/repo/$pkgdir" \
  archlinux:base-devel \
  bash -lc 'set -euo pipefail
pacman -Syu --noconfirm --needed pacman-contrib sudo
useradd --create-home --shell /bin/bash builder
chown -R builder:builder .
sudo -u builder bash -lc "updpkgsums && makepkg --printsrcinfo > .SRCINFO"'
