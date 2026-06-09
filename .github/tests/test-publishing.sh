#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SELECT_PUBLISHER="$REPO_ROOT/.github/scripts/select-publisher.sh"
PUBLISH_PRIVATE="$REPO_ROOT/.github/scripts/publish-private.sh"

failures=0
current_test=""

fail() {
  echo "not ok - $current_test: $*" >&2
  failures=$((failures + 1))
}

assert_equals() {
  local expected="$1"
  local actual="$2"

  if [[ "$actual" != "$expected" ]]; then
    fail "expected '$expected', got '$actual'"
  fi
}

assert_contains() {
  local needle="$1"
  local haystack="$2"

  if [[ "$haystack" != *"$needle"* ]]; then
    fail "expected output to contain '$needle'; output was: $haystack"
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

make_package_directory() {
  local root="$1"
  local package_name="${2:-example-bin}"
  local package_directory="$root/$package_name"

  mkdir -p "$package_directory"
  cat >"$package_directory/PKGBUILD" <<'PKGBUILD'
pkgname=example-bin
pkgver=1.0.0
pkgrel=1
pkgdesc='Example package for publisher tests'
arch=('x86_64')
license=('MIT')
source=()
sha256sums=()

package() {
  install -dm755 "$pkgdir/usr/share/example-bin"
}
PKGBUILD

  printf '%s\n' "$package_directory"
}

test_selects_aur_by_default() {
  local temp_dir package_directory actual

  temp_dir="$(mktemp -d)"
  package_directory="$(make_package_directory "$temp_dir")"

  actual="$(cd "$temp_dir" && bash "$SELECT_PUBLISHER" "$(basename "$package_directory")")"
  assert_equals "aur" "$actual"
}

test_selects_private_when_marker_exists() {
  local temp_dir package_directory actual

  temp_dir="$(mktemp -d)"
  package_directory="$(make_package_directory "$temp_dir")"
  : >"$package_directory/.private"

  actual="$(cd "$temp_dir" && bash "$SELECT_PUBLISHER" "$(basename "$package_directory")")"
  assert_equals "private" "$actual"
}

test_private_config_is_only_required_by_private_publisher() {
  local temp_dir package_directory output status

  temp_dir="$(mktemp -d)"
  package_directory="$(make_package_directory "$temp_dir")"
  : >"$package_directory/.private"

  set +e
  output="$(cd "$temp_dir" && env -u PRIVATE_REPO_UPLOAD_URL -u PRIVATE_REPO_UPLOAD_TOKEN bash "$PUBLISH_PRIVATE" "$(basename "$package_directory")" 2>&1)"
  status=$?
  set -e

  if [[ "$status" -eq 0 ]]; then
    fail "expected missing private config to fail"
  fi

  assert_contains "missing_private_repo_upload_url" "$output"
}

test_validate_response_payload_accepts_success_json() {
  local response_file

  response_file="$(mktemp)"
  echo '{"ok":true}' >"$response_file"

  source "$PUBLISH_PRIVATE"
  validate_response_payload "201" "$response_file" "/tmp/example.pkg.tar.zst"
}

test_validate_response_payload_rejects_http_failure() {
  local response_file status

  response_file="$(mktemp)"
  echo '{"ok":true}' >"$response_file"

  source "$PUBLISH_PRIVATE"

  set +e
  validate_response_payload "500" "$response_file" "/tmp/example.pkg.tar.zst" >/tmp/private-publish-test.out 2>&1
  status=$?
  set -e

  if [[ "$status" -eq 0 ]]; then
    fail "expected HTTP 500 response to fail validation"
  fi
}

test_validate_response_payload_rejects_empty_response() {
  local response_file status

  response_file="$(mktemp)"

  source "$PUBLISH_PRIVATE"

  set +e
  validate_response_payload "200" "$response_file" "/tmp/example.pkg.tar.zst" >/tmp/private-publish-test.out 2>&1
  status=$?
  set -e

  if [[ "$status" -eq 0 ]]; then
    fail "expected empty response to fail validation"
  fi
}

test_upload_uses_bearer_auth_and_multipart_form() {
  local temp_dir fake_curl response_file output status

  temp_dir="$(mktemp -d)"
  response_file="$temp_dir/response.json"
  fake_curl="$temp_dir/fake-curl"

  cat >"$fake_curl" <<'CURL'
#!/usr/bin/env bash
set -euo pipefail

output_file=""
args_file="${PRIVATE_PUBLISH_CURL_ARGS_FILE:?}"

while (($# > 0)); do
  case "$1" in
    --output)
      output_file="$2"
      shift 2
      ;;
    *)
      printf '%s\n' "$1" >>"$args_file"
      shift
      ;;
  esac
done

printf '{"ok":true}\n' >"$output_file"
printf '201'
CURL
  chmod +x "$fake_curl"

  : >"$temp_dir/example.pkg.tar.zst"

  source "$PUBLISH_PRIVATE"

  export PRIVATE_REPO_UPLOAD_URL="https://repo.example.test/upload"
  export PRIVATE_REPO_UPLOAD_TOKEN="test-token"
  export PRIVATE_PUBLISH_CURL_BIN="$fake_curl"
  export PRIVATE_PUBLISH_CURL_ARGS_FILE="$temp_dir/curl-args.txt"

  set +e
  upload_package_artifact "$temp_dir/example.pkg.tar.zst" >/tmp/private-publish-test.out 2>&1
  status=$?
  set -e

  if [[ "$status" -ne 0 ]]; then
    output="$(cat /tmp/private-publish-test.out)"
    fail "expected upload to succeed; output was: $output"
  fi

  output="$(cat "$PRIVATE_PUBLISH_CURL_ARGS_FILE")"
  assert_contains "Authorization: Bearer test-token" "$output"
  assert_contains "file=@$temp_dir/example.pkg.tar.zst" "$output"
  assert_contains "https://repo.example.test/upload" "$output"
}

test_find_package_artifacts_lists_pkg_tar_zst_only() {
  local temp_dir output expected

  temp_dir="$(mktemp -d)"
  : >"$temp_dir/a.pkg.tar.zst"
  : >"$temp_dir/a.pkg.tar.zst.sig"
  : >"$temp_dir/source.tar.gz"

  source "$PUBLISH_PRIVATE"

  output="$(find_package_artifacts "$temp_dir")"
  expected="$temp_dir/a.pkg.tar.zst"
  assert_equals "$expected" "$output"
}

run_test "selects AUR by default" test_selects_aur_by_default
run_test "selects private when .private exists" test_selects_private_when_marker_exists
run_test "private config required only by private publisher" test_private_config_is_only_required_by_private_publisher
run_test "validates successful JSON response" test_validate_response_payload_accepts_success_json
run_test "rejects HTTP failure" test_validate_response_payload_rejects_http_failure
run_test "rejects empty response" test_validate_response_payload_rejects_empty_response
run_test "uploads with bearer auth and multipart form" test_upload_uses_bearer_auth_and_multipart_form
run_test "finds pkg.tar.zst artifacts only" test_find_package_artifacts_lists_pkg_tar_zst_only

if ((failures > 0)); then
  echo "$failures test(s) failed" >&2
  exit 1
fi
