#!/usr/bin/env bash
set -euo pipefail

pkgdir="${1:-.}"

case "$pkgdir" in
  /*|*..*|*' '*|'')
    echo "Unsupported package directory: $pkgdir" >&2
    exit 2
    ;;
esac

if [[ ! "$pkgdir" =~ ^[A-Za-z0-9._/-]+$ ]]; then
  echo "Unsupported package directory: $pkgdir" >&2
  exit 2
fi

if [[ "$pkgdir" != "." ]]; then
  if [[ ! -d "$pkgdir" ]]; then
    echo "Package directory does not exist: $pkgdir" >&2
    exit 2
  fi
  cd "$pkgdir"
fi

if [[ ! -f PKGBUILD ]]; then
  echo "PKGBUILD not found in: $PWD" >&2
  exit 2
fi

attempts="${AUR_REFRESH_ATTEMPTS:-18}"
delay_seconds="${AUR_REFRESH_DELAY_SECONDS:-300}"

if ! [[ "$attempts" =~ ^[0-9]+$ ]] || ((attempts < 1)); then
  echo "AUR_REFRESH_ATTEMPTS must be a positive integer; got: $attempts" >&2
  exit 2
fi

if ! [[ "$delay_seconds" =~ ^[0-9]+$ ]]; then
  echo "AUR_REFRESH_DELAY_SECONDS must be a non-negative integer; got: $delay_seconds" >&2
  exit 2
fi

run_with_retry() {
  local description="$1"
  shift

  local attempt=1
  local status=0

  while true; do
    echo "::group::${description} (attempt ${attempt}/${attempts})"
    set +e
    "$@"
    status=$?
    set -e
    echo "::endgroup::"

    if ((status == 0)); then
      return 0
    fi

    if ((attempt >= attempts)); then
      echo "::error::${description} failed after ${attempts} attempts" >&2
      return "$status"
    fi

    echo "::warning::${description} failed with exit code ${status}. Upstream release assets may still be publishing; retrying in ${delay_seconds}s." >&2
    sleep "$delay_seconds"
    attempt=$((attempt + 1))
  done
}

check_github_release_assets() {
  local line value url
  local missing=0
  local checked=0

  echo "::group::Checking GitHub release asset URLs"
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*source(_[A-Za-z0-9_]+)?[[:space:]]*= ]] || continue

    value="${line#*=}"
    value="${value#${value%%[![:space:]]*}}"
    url="${value##*::}"

    [[ "$url" == https://github.com/*/releases/download/* ]] || continue

    checked=$((checked + 1))
    echo "Checking $url"
    if ! curl -fsIL --retry 3 --retry-all-errors --connect-timeout 20 --max-time 120 "$url" >/dev/null; then
      echo "::error::Required GitHub release asset is not downloadable: $url" >&2
      missing=1
    fi
  done < <(makepkg --printsrcinfo)
  echo "::endgroup::"

  if ((checked == 0)); then
    echo "No GitHub release asset URLs found in PKGBUILD sources."
  fi

  if ((missing != 0)); then
    echo "::error::One or more required GitHub release assets are missing. This usually means Renovate selected a tag/release before upstream uploaded the package assets needed by this PKGBUILD, or upstream published an incomplete release. Rebase/retry only after the missing assets exist upstream." >&2
    return 1
  fi
}

check_github_release_assets
run_with_retry "Updating checksums on PKGBUILD" updpkgsums
run_with_retry "Verifying source availability and checksums" makepkg --nobuild --nodeps --verifysource
makepkg --printsrcinfo > .SRCINFO
