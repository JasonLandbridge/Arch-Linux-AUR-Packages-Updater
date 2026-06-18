#!/usr/bin/env bash
set -euo pipefail

pkgdir="${1:?package directory required}"

case "$pkgdir" in
  /*|*..*|*' '*|'')
    echo "Unsupported package directory: $pkgdir" >&2
    exit 2
    ;;
esac

if [[ ! -d "$pkgdir" ]]; then
  echo "Package directory does not exist: $pkgdir" >&2
  exit 2
fi

echo "Refreshing AUR package metadata for: $pkgdir"
echo "Working directory: $PWD"
echo "Docker availability:"
command -v docker || true
docker version || true

docker run --rm \
  -v "$PWD":/repo \
  -w /repo \
  archlinux:base-devel \
  bash -lc "set -euo pipefail
pacman -Syu --noconfirm --needed pacman-contrib sudo
useradd --create-home --shell /bin/bash builder
chown -R builder:builder '$pkgdir'
sudo -u builder AUR_REFRESH_ATTEMPTS=18 AUR_REFRESH_DELAY_SECONDS=300 bash .github/scripts/aur-refresh-metadata.sh '$pkgdir'"
