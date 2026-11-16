#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REFRESH_METADATA="$REPO_ROOT/.github/scripts/aur-refresh-metadata.sh"

failures=0
current_test=""

fail() {
  echo "not ok - $current_test: $*" >&2
  failures=$((failures + 1))
}

assert_contains() {
  local needle="$1"
  local haystack="$2"

  if [[ "$haystack" != *"$needle"* ]]; then
    fail "expected output to contain '$needle'; output was: $haystack"
  fi
}

assert_not_contains() {
  local needle="$1"
  local haystack="$2"

  if [[ "$haystack" == *"$needle"* ]]; then
    fail "expected output not to contain '$needle'; output was: $haystack"
  fi
}

run_test() {
  current_test="$1"
  shift

  if "$@"; then
    echo "ok - $current_test"
  else
    fail "test command returned non-zero"
  fi
}

test_metadata_refresh_runs_pkgver_without_build() {
  local temp_dir upstream_repo package_dir release_dir fake_bin output_one output_two output_release
  local build_marker prepare_marker release_build_marker first_commit second_commit
  local first_short second_short expected_first expected_second fixture pkgver_value srcinfo

  temp_dir="$(mktemp -d)"
  upstream_repo="$temp_dir/upstream"
  package_dir="$temp_dir/example"
  release_dir="$temp_dir/release"
  fake_bin="$temp_dir/bin"
  output_one="$temp_dir/output-one.log"
  output_two="$temp_dir/output-two.log"
  output_release="$temp_dir/output-release.log"
  build_marker="$temp_dir/build-called"
  prepare_marker="$temp_dir/prepare-called"
  release_build_marker="$temp_dir/release-build-called"
  mkdir -p "$upstream_repo" "$package_dir" "$release_dir" "$fake_bin"

  git -C "$upstream_repo" init -q
  git -C "$upstream_repo" config user.email test@example.invalid
  git -C "$upstream_repo" config user.name 'Metadata Refresh Test'
  printf '%s\n' 'fixture' >"$upstream_repo/input"
  git -C "$upstream_repo" add input
  git -C "$upstream_repo" commit -qm initial
  git -C "$upstream_repo" tag v1.0
  first_commit="$(git -C "$upstream_repo" rev-parse HEAD)"
  printf '%s\n' 'second fixture' >>"$upstream_repo/input"
  git -C "$upstream_repo" add input
  git -C "$upstream_repo" commit -qm second
  second_commit="$(git -C "$upstream_repo" rev-parse HEAD)"
  first_short="$(git -C "$upstream_repo" rev-parse --short "$first_commit")"
  second_short="$(git -C "$upstream_repo" rev-parse --short "$second_commit")"
  expected_first="1.0.r0.g${first_short}"
  expected_second="1.0.r1.g${second_short}"

  cat >"$package_dir/PKGBUILD" <<'PKGBUILD'
pkgname=example-git
pkgver=0.0.0
pkgrel=1
pkgdesc='Example package for metadata refresh tests'
arch=('x86_64')
license=('MIT')
_commit=COMMIT
source=("example::git+file://REPO#commit=${_commit}")
sha256sums=('SKIP')
makedepends=('git')

pkgver() {
  cd "${srcdir}/example"

  git describe --long --tags 2>/dev/null | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g'
  [ ${PIPESTATUS[0]} -eq 0 ] || \
    printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

build() {
  touch "BUILD_MARKER"
}

package() {
  install -dm755 "${pkgdir}/usr/share/example-git"
}
PKGBUILD
  fixture="$(cat "$package_dir/PKGBUILD")"
  fixture="${fixture//COMMIT/$first_commit}"
  fixture="${fixture//REPO/$upstream_repo}"
  fixture="${fixture//BUILD_MARKER/$build_marker}"
  printf '%s\n' "$fixture" >"$package_dir/PKGBUILD"

  cat >"$release_dir/PKGBUILD" <<'PKGBUILD'
pkgname=example-release
pkgver=1.0.0
pkgrel=1
pkgdesc='Example release package for metadata refresh tests'
arch=('x86_64')
license=('MIT')
source=()
sha256sums=()

prepare() {
  touch "PREPARE_MARKER"
}

build() {
  touch "RELEASE_BUILD_MARKER"
}

package() {
  install -dm755 "${pkgdir}/usr/share/example-release"
}
PKGBUILD
  fixture="$(cat "$release_dir/PKGBUILD")"
  fixture="${fixture//PREPARE_MARKER/$prepare_marker}"
  fixture="${fixture//RELEASE_BUILD_MARKER/$release_build_marker}"
  printf '%s\n' "$fixture" >"$release_dir/PKGBUILD"

  cat >"$fake_bin/updpkgsums" <<'UPDPKGSUMS'
#!/usr/bin/env bash
set -euo pipefail
UPDPKGSUMS
  chmod +x "$fake_bin/updpkgsums"

  if (( EUID == 0 )); then
    chown -R nobody:nobody "$temp_dir"
  fi

  run_refresh() {
    local package_name="$1"
    local refresh_output="$2"

    if (( EUID == 0 )); then
      (
        cd "$temp_dir"
        runuser -u nobody -- env HOME="$temp_dir" LC_ALL=C \
          AUR_REFRESH_ATTEMPTS=1 AUR_REFRESH_DELAY_SECONDS=0 \
          PATH="$fake_bin:$PATH" bash "$REFRESH_METADATA" "$package_name" >"$refresh_output"
      )
    else
      (
        cd "$temp_dir"
        HOME="$temp_dir" LC_ALL=C \
          AUR_REFRESH_ATTEMPTS=1 AUR_REFRESH_DELAY_SECONDS=0 \
          PATH="$fake_bin:$PATH" bash "$REFRESH_METADATA" "$package_name" >"$refresh_output"
      )
    fi
  }

  read_pkgver() {
    local package_build="$1"
    local line

    while IFS= read -r line; do
      if [[ "$line" == pkgver=* ]]; then
        printf '%s\n' "${line#pkgver=}"
        return
      fi
    done <"$package_build"
  }

  run_refresh example "$output_one"
  pkgver_value="$(read_pkgver "$package_dir/PKGBUILD")"
  if [[ "$pkgver_value" != "$expected_first" ]]; then
    fail "expected first pkgver '$expected_first', got '$pkgver_value'"
  fi
  srcinfo="$(cat "$package_dir/.SRCINFO")"
  assert_contains "pkgver = $expected_first" "$srcinfo"
  assert_not_contains 'pkgver = 0.0.0' "$srcinfo"
  assert_contains 'Starting pkgver()' "$(cat "$output_one")"

  fixture="$(cat "$package_dir/PKGBUILD")"
  fixture="${fixture//_commit=$first_commit/_commit=$second_commit}"
  printf '%s\n' "$fixture" >"$package_dir/PKGBUILD"
  if (( EUID == 0 )); then
    chown -R nobody:nobody "$temp_dir"
  fi
  run_refresh example "$output_two"
  pkgver_value="$(read_pkgver "$package_dir/PKGBUILD")"
  if [[ "$pkgver_value" != "$expected_second" ]]; then
    fail "expected second pkgver '$expected_second', got '$pkgver_value'"
  fi
  srcinfo="$(cat "$package_dir/.SRCINFO")"
  assert_contains "pkgver = $expected_second" "$srcinfo"
  assert_not_contains "pkgver = $expected_first" "$srcinfo"
  assert_contains 'Starting pkgver()' "$(cat "$output_two")"
  if [[ -e "$build_marker" ]]; then
    fail "metadata refresh ran build() despite --nobuild"
  fi

  run_refresh release "$output_release"
  srcinfo="$(cat "$release_dir/.SRCINFO")"
  assert_contains 'pkgver = 1.0.0' "$srcinfo"
  if [[ -e "$prepare_marker" ]]; then
    fail "release metadata refresh ran prepare() despite --verifysource"
  fi
  if [[ -e "$release_build_marker" ]]; then
    fail "release metadata refresh ran build()"
  fi
}

run_test "refreshes VCS and release metadata safely" test_metadata_refresh_runs_pkgver_without_build
if ((failures > 0)); then
  echo "$failures test(s) failed" >&2
  exit 1
fi
