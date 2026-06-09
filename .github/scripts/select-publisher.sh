#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 <package-directory>" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 64
fi

package_directory="${1%/}"

if [[ -z "$package_directory" ]]; then
  usage
  exit 64
fi

if [[ ! -d "$package_directory" ]]; then
  echo "Package directory does not exist: $package_directory" >&2
  exit 66
fi

if [[ ! -f "$package_directory/PKGBUILD" ]]; then
  echo "Package directory does not contain a PKGBUILD: $package_directory" >&2
  exit 66
fi

if [[ -e "$package_directory/.private" ]]; then
  echo "private"
else
  echo "aur"
fi
