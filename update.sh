#!/bin/sh
set -eu
repo="strut-labs/strut"; base="https://github.com/$repo/releases"
install_dir=${STRUT_INSTALL_DIR:-"$HOME/.local/opt/strut"}; bin_dir=${STRUT_BIN_DIR:-"$HOME/.local/bin"}
fail() { printf 'strut update: %s\n' "$*" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || fail "curl is required"
[ -x "$install_dir/bin/strut" ] || fail "no Strut installation found at $install_dir; run install.sh first"
[ -f "$install_dir/.strut-install-manifest" ] || fail "installation manifest is missing; refusing replacement"
grep -qx 'strut-install-v1' "$install_dir/.strut-install-manifest" || fail "installation manifest is invalid"
grep -Fqx "install_dir=$install_dir" "$install_dir/.strut-install-manifest" || fail "installation manifest path mismatch"
[ ! -e "$bin_dir/strut" ] && [ ! -L "$bin_dir/strut" ] || { [ -L "$bin_dir/strut" ] && [ "$(readlink "$bin_dir/strut")" = "$install_dir/bin/strut" ] || fail "refusing to replace unrelated command: $bin_dir/strut"; }
current=$("$install_dir/bin/strut" --version | awk '{print $2}')
latest_url=$(curl -fsSL -o /dev/null -w '%{url_effective}' "$base/latest") || fail "could not resolve latest release"
latest=${latest_url##*/}; latest=${latest#v}
[ "$current" != "$latest" ] || { printf 'Strut %s is already current.\n' "$current"; exit 0; }
os=${STRUT_TEST_OS:-$(uname -s)}; arch=${STRUT_TEST_ARCH:-$(uname -m)}
case "$os:$arch" in Linux:x86_64|Linux:amd64) platform=linux-x64 ;; Linux:aarch64|Linux:arm64) platform=linux-arm64 ;; Darwin:arm64|Darwin:aarch64) platform=macos-arm64 ;; *) fail "unsupported platform: $os $arch" ;; esac
parent=$(dirname "$install_dir"); work=$(mktemp -d "$parent/.strut-update.XXXXXX"); backup="$parent/.strut-backup.$$"
trap 'rm -rf "$work"' EXIT HUP INT TERM
archive="strut-$latest-$platform.tar.gz"
curl -fL --proto '=https' --tlsv1.2 -o "$work/$archive" "$base/download/v$latest/$archive" || fail "could not download $archive"
curl -fL --proto '=https' --tlsv1.2 -o "$work/SHA256SUMS" "$base/download/v$latest/SHA256SUMS" 2>/dev/null || rm -f "$work/SHA256SUMS"
if [ -f "$work/SHA256SUMS" ]; then
    expected=$(awk -v name="$archive" '$2 == name || $2 == "*" name { print $1; exit }' "$work/SHA256SUMS"); [ -n "$expected" ] || fail "checksum entry is missing"
    if command -v sha256sum >/dev/null 2>&1; then actual=$(sha256sum "$work/$archive" | awk '{print $1}'); else actual=$(shasum -a 256 "$work/$archive" | awk '{print $1}'); fi
    [ "$actual" = "$expected" ] || fail "checksum mismatch"
else printf 'strut update: SHA256SUMS is not published for v%s; continuing with verified HTTPS\n' "$latest" >&2
fi
tar -xzf "$work/$archive" -C "$work"; payload="$work/strut-$latest-$platform"
[ -x "$payload/bin/strut" ] && [ -f "$payload/share/strut/jsonic/json.h" ] || fail "release archive has an invalid layout"
printf 'strut-install-v1\ninstall_dir=%s\nbin_link=%s\nversion=%s\n' "$install_dir" "$bin_dir/strut" "$latest" > "$payload/.strut-install-manifest"
mv "$install_dir" "$backup"
if ! mv "$payload" "$install_dir"; then mv "$backup" "$install_dir"; fail "could not activate update"; fi
ln -sfn "$install_dir/bin/strut" "$bin_dir/strut"; rm -rf "$backup"
[ "$("$install_dir/bin/strut" --version | awk '{print $2}')" = "$latest" ] || fail "updated compiler failed verification"
printf 'Updated Strut from %s to %s in %s.\n' "$current" "$latest" "$install_dir"
