#!/usr/bin/env bash
set -euo pipefail

PRIVATE_MARKER_NAME=".private"

log_info() {
  local event="$1"
  shift || true
  printf 'level=info event=%s %s\n' "$event" "$*" >&2
}

log_error() {
  local event="$1"
  shift || true
  printf 'level=error event=%s %s\n' "$event" "$*" >&2
}

die() {
  local event="$1"
  local message="$2"
  log_error "$event" "message=$(printf '%q' "$message")"
  exit 1
}

usage() {
  echo "usage: $0 <private-package-directory>" >&2
}

require_private_repository_config() {
  if [[ -z "${PRIVATE_REPO_UPLOAD_URL:-}" ]]; then
    die "missing_private_repo_upload_url" "PRIVATE_REPO_UPLOAD_URL is required for private packages"
  fi

  if [[ -z "${PRIVATE_REPO_UPLOAD_TOKEN:-}" ]]; then
    die "missing_private_repo_upload_token" "PRIVATE_REPO_UPLOAD_TOKEN is required for private packages"
  fi
}

ensure_private_package_directory() {
  local package_directory="$1"

  if [[ ! -d "$package_directory" ]]; then
    die "package_directory_missing" "Package directory does not exist: $package_directory"
  fi

  if [[ ! -f "$package_directory/PKGBUILD" ]]; then
    die "pkgbuild_missing" "Package directory does not contain a PKGBUILD: $package_directory"
  fi

  if [[ ! -e "$package_directory/$PRIVATE_MARKER_NAME" ]]; then
    die "private_marker_missing" "Package is not marked private: $package_directory/$PRIVATE_MARKER_NAME"
  fi
}

install_build_dependencies() {
  log_info "install_build_tooling" "packages=pacman-contrib,curl,git,sudo,python"
  pacman-key --init
  pacman-key --populate archlinux
  pacman -Sy --needed --noconfirm pacman-contrib curl git sudo python
}

ensure_builder_user() {
  if ! id -u builder >/dev/null 2>&1; then
    useradd -m builder
  fi

  if ! grep -q '^builder ALL=(ALL) NOPASSWD: ALL$' /etc/sudoers; then
    echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
  fi
}

copy_package_to_build_directory() {
  local package_directory="$1"
  local build_directory="$2"

  rm -rf "$build_directory"
  install -d -o builder -g builder "$build_directory"
  cp -a "$package_directory/." "$build_directory/"
  chown -R builder:builder "$build_directory"
}

install_package_dependencies() {
  local build_directory="$1"

  mapfile -t packages_to_install < <(
    cd "$build_directory"
    bash -euo pipefail <<'PKGDEPS'
source PKGBUILD
packages=()
if declare -p depends >/dev/null 2>&1; then
  packages+=("${depends[@]}")
fi
if declare -p makedepends >/dev/null 2>&1; then
  packages+=("${makedepends[@]}")
fi
printf '%s\n' "${packages[@]}"
PKGDEPS
  )

  if ((${#packages_to_install[@]} == 0)); then
    log_info "install_package_dependencies" "count=0"
    return
  fi

  log_info "install_package_dependencies" "count=${#packages_to_install[@]}"
  pacman -S --needed --noconfirm "${packages_to_install[@]}"
}

package_build_directory() {
  local package_directory="$1"
  local build_root="${PRIVATE_PUBLISH_BUILD_ROOT:-/tmp/private-publish}"

  printf '%s\n' "$build_root/${package_directory//\//-}"
}

build_package() {
  local package_directory="$1"
  local build_directory="$2"

  log_info "build_start" "package=$package_directory build_directory=$build_directory"

  install_build_dependencies
  ensure_builder_user
  copy_package_to_build_directory "$package_directory" "$build_directory"
  install_package_dependencies "$build_directory"

  runuser -u builder -- bash -lc "cd '$build_directory' && makepkg --cleanbuild --force --noconfirm --skipinteg"

  log_info "build_complete" "package=$package_directory build_directory=$build_directory"
}

find_package_artifacts() {
  local build_directory="$1"

  mapfile -t artifacts < <(find "$build_directory" -maxdepth 1 -type f -name '*.pkg.tar.zst' | sort)

  if ((${#artifacts[@]} == 0)); then
    die "package_artifact_missing" "No .pkg.tar.zst artifacts were generated in $build_directory"
  fi

  printf '%s\n' "${artifacts[@]}"
}

validate_package_artifact() {
  local artifact="$1"

  if [[ ! -s "$artifact" ]]; then
    die "package_artifact_empty" "Generated package artifact is empty: $artifact"
  fi

  tar -tf "$artifact" >/dev/null
  log_info "package_artifact_validated" "artifact=$(basename "$artifact")"
}

validate_response_payload() {
  local status_code="$1"
  local response_file="$2"
  local artifact="$3"

  if [[ ! "$status_code" =~ ^2[0-9][0-9]$ ]]; then
    log_error "private_upload_http_failure" "artifact=$(basename "$artifact") status=$status_code response_file=$response_file"
    cat "$response_file" >&2 || true
    return 1
  fi

  if [[ ! -s "$response_file" ]]; then
    log_error "private_upload_empty_response" "artifact=$(basename "$artifact") status=$status_code"
    return 1
  fi

  python - "$response_file" <<'PY'
import json
import pathlib
import sys

response_path = pathlib.Path(sys.argv[1])
payload = response_path.read_text(encoding="utf-8", errors="replace").strip()

try:
    parsed = json.loads(payload)
except json.JSONDecodeError:
    sys.exit(0)

if isinstance(parsed, dict):
    for key in ("ok", "success"):
        if parsed.get(key) is False:
            print(f"response field {key}=false", file=sys.stderr)
            sys.exit(1)

    status = str(parsed.get("status", "")).lower()
    if status in {"error", "failed", "failure"}:
        print(f"response status={status}", file=sys.stderr)
        sys.exit(1)
PY
}

private_upload_url() {
  local upload_url="$1"
  local separator="?"

  if [[ "$upload_url" == *\?* ]]; then
    separator="&"
  fi

  printf '%s%soverwrite=true\n' "$upload_url" "$separator"
}

upload_package_artifact() {
  local artifact="$1"
  local curl_bin="${PRIVATE_PUBLISH_CURL_BIN:-curl}"
  local response_file
  local status_code
  local upload_url

  response_file="$(mktemp)"
  upload_url="$(private_upload_url "$PRIVATE_REPO_UPLOAD_URL")"

  log_info "private_upload_start" "artifact=$(basename "$artifact")"

  status_code="$(
    "$curl_bin" \
      --silent \
      --show-error \
      --location \
      --output "$response_file" \
      --write-out '%{http_code}' \
      --request POST \
      --header "Authorization: Bearer $PRIVATE_REPO_UPLOAD_TOKEN" \
      --form "file=@${artifact}" \
      "$upload_url"
  )"

  validate_response_payload "$status_code" "$response_file" "$artifact"
  log_info "private_upload_complete" "artifact=$(basename "$artifact") status=$status_code"

  rm -f "$response_file"
}

main() {
  if [[ $# -ne 1 ]]; then
    usage
    exit 64
  fi

  local package_directory="${1%/}"
  local build_directory
  local artifacts

  require_private_repository_config
  ensure_private_package_directory "$package_directory"

  build_directory="$(package_build_directory "$package_directory")"
  build_package "$package_directory" "$build_directory"
  mapfile -t artifacts < <(find_package_artifacts "$build_directory")

  for artifact in "${artifacts[@]}"; do
    validate_package_artifact "$artifact"
    upload_package_artifact "$artifact"
  done

  log_info "private_publish_complete" "package=$package_directory artifacts=${#artifacts[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
