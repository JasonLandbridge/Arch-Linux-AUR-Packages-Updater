#!/usr/bin/env bash
set -euo pipefail

echo "::group::Updating"
sudo pacman -Syu --noconfirm
echo "::endgroup::"

# Set path
WORKPATH=$GITHUB_WORKSPACE/$INPUT_PKGNAME
HOME=/home/builder
echo "::group::Copying files from $WORKPATH to $HOME/gh-action"
# Set path permision
cd $HOME
mkdir gh-action
cd gh-action
cp -rfv "$GITHUB_WORKSPACE"/.git ./
# Copy the package directory contents, including dotfiles like .env.example.
cp -af "$WORKPATH"/. .
echo "::endgroup::"

echo "::group::Updating archlinux-keyring"
sudo pacman -S --noconfirm archlinux-keyring
echo "::endgroup::"

echo "::group::Updating checksums on PKGBUILD"
updpkgsums
git diff PKGBUILD
echo "::endgroup::"

echo "::group::Installing depends using paru"
source PKGBUILD
packages_to_install=()
if declare -p depends >/dev/null 2>&1; then
  packages_to_install+=("${depends[@]}")
fi
if declare -p makedepends >/dev/null 2>&1; then
  packages_to_install+=("${makedepends[@]}")
fi
if ((${#packages_to_install[@]} > 0)); then
  sudo pacman -S --needed --noconfirm "${packages_to_install[@]}"
else
  echo "No depends or makedepends to install"
fi
echo "::endgroup::"

echo "::group::Running makepkg"
makepkg
echo "::endgroup::"

echo "::group::Generating new .SRCINFO based on PKGBUILD"
makepkg --printsrcinfo >.SRCINFO
git diff .SRCINFO
echo "::endgroup::"

echo "::group::Copying files from $HOME/gh-action to $WORKPATH"
sudo cp -fv PKGBUILD "$WORKPATH"/PKGBUILD
sudo cp -fv .SRCINFO "$WORKPATH"/.SRCINFO
echo "::endgroup::"
