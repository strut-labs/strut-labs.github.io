#!/bin/sh
set -eu

repo="strut-labs/strut"
base="https://github.com/$repo/releases"
install_dir=${STRUT_INSTALL_DIR:-"$HOME/.local/opt/strut"}
bin_dir=${STRUT_BIN_DIR:-"$HOME/.local/bin"}
version=${STRUT_VERSION:-}

fail() { printf 'strut install: %s\n' "$*" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || fail "curl is required"
command -v tar >/dev/null 2>&1 || fail "tar is required"
[ -n "$install_dir" ] || fail "install directory is empty"
case "$install_dir" in /|"$HOME"|"$HOME/.local") fail "refusing unsafe install directory: $install_dir" ;; esac
if [ -e "$install_dir" ]; then
    manifest="$install_dir/.strut-install-manifest"
    [ -f "$manifest" ] && grep -qx 'strut-install-v1' "$manifest" && grep -Fqx "install_dir=$install_dir" "$manifest" || fail "existing directory is not a managed Strut installation: $install_dir"
fi
if [ -e "$bin_dir/strut" ] || [ -L "$bin_dir/strut" ]; then
    [ -L "$bin_dir/strut" ] && [ "$(readlink "$bin_dir/strut")" = "$install_dir/bin/strut" ] || fail "refusing to replace unrelated command: $bin_dir/strut"
fi

if [ -z "$version" ]; then
    latest=$(curl -fsSL -o /dev/null -w '%{url_effective}' "$base/latest") || fail "could not resolve the latest stable release"
    version=${latest##*/}
fi
version=${version#v}
os=${STRUT_TEST_OS:-$(uname -s)}; arch=${STRUT_TEST_ARCH:-$(uname -m)}
case "$os:$arch" in
    Linux:x86_64|Linux:amd64) platform=linux-x64 ;;
    Linux:aarch64|Linux:arm64) platform=linux-arm64 ;;
    Darwin:arm64|Darwin:aarch64) platform=macos-arm64 ;;
    *) fail "unsupported platform: $os $arch" ;;
esac

parent=$(dirname "$install_dir"); mkdir -p "$parent" "$bin_dir"
work=$(mktemp -d "$parent/.strut-install.XXXXXX")
backup="$parent/.strut-backup.$$"
cleanup() { rm -rf "$work"; }
trap cleanup EXIT HUP INT TERM
archive="strut-$version-$platform.tar.gz"
curl -fL --proto '=https' --tlsv1.2 -o "$work/$archive" "$base/download/v$version/$archive" || fail "could not download $archive"
curl -fL --proto '=https' --tlsv1.2 -o "$work/SHA256SUMS" "$base/download/v$version/SHA256SUMS" 2>/dev/null || rm -f "$work/SHA256SUMS"
if [ -f "$work/SHA256SUMS" ]; then
    expected=$(awk -v name="$archive" '$2 == name || $2 == "*" name { print $1; exit }' "$work/SHA256SUMS"); [ -n "$expected" ] || fail "checksum entry is missing"
    if command -v sha256sum >/dev/null 2>&1; then actual=$(sha256sum "$work/$archive" | awk '{print $1}'); else actual=$(shasum -a 256 "$work/$archive" | awk '{print $1}'); fi
    [ "$actual" = "$expected" ] || fail "checksum mismatch"
else printf 'strut install: SHA256SUMS is not published for v%s; continuing with verified HTTPS\n' "$version" >&2
fi
tar -xzf "$work/$archive" -C "$work"
payload="$work/strut-$version-$platform"
[ -x "$payload/bin/strut" ] && [ -f "$payload/share/strut/jsonic/json.h" ] || fail "release archive has an invalid layout"
printf 'strut-install-v1\ninstall_dir=%s\nbin_link=%s\nversion=%s\n' "$install_dir" "$bin_dir/strut" "$version" > "$payload/.strut-install-manifest"
[ ! -e "$backup" ] || fail "temporary backup path already exists"
if [ -e "$install_dir" ]; then mv "$install_dir" "$backup"; fi
if ! mv "$payload" "$install_dir"; then [ ! -e "$backup" ] || mv "$backup" "$install_dir"; fail "could not activate installation"; fi
ln -sfn "$install_dir/bin/strut" "$bin_dir/strut"
rm -rf "$backup"
installed=$("$install_dir/bin/strut" --version) || fail "installed compiler failed verification"
printf 'Installed %s in %s\n' "$installed" "$install_dir"
case ":$PATH:" in *:"$bin_dir":*) ;; *) printf 'Add %s to PATH, for example:\n  export PATH="%s:$PATH"\n' "$bin_dir" "$bin_dir" ;; esac
