#!/bin/sh
set -eu

repo="strut-labs/strut"
base="https://github.com/$repo/releases"
version=${1:-}
destination=${2:-${STRUT_DOWNLOAD_DIR:-.}}

fail() { printf 'strut download: %s\n' "$*" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || fail "curl is required"

if [ -z "$version" ]; then
    latest=$(curl -fsSL -o /dev/null -w '%{url_effective}' "$base/latest") || fail "could not resolve the latest stable release"
    version=${latest##*/}
fi
version=${version#v}

os=${STRUT_TEST_OS:-$(uname -s)}
arch=${STRUT_TEST_ARCH:-$(uname -m)}
case "$os:$arch" in
    Linux:x86_64|Linux:amd64) platform=linux-x64; extension=tar.gz ;;
    Linux:aarch64|Linux:arm64) platform=linux-arm64; extension=tar.gz ;;
    Darwin:arm64|Darwin:aarch64) platform=macos-arm64; extension=tar.gz ;;
    *) fail "unsupported platform: $os $arch" ;;
esac

mkdir -p "$destination"
archive="strut-$version-$platform.$extension"
output="$destination/$archive"
curl -fL --proto '=https' --tlsv1.2 -o "$output.part" "$base/download/v$version/$archive" || { rm -f "$output.part"; fail "could not download $archive"; }
mv "$output.part" "$output"

checksums="$destination/SHA256SUMS"
if curl -fL --proto '=https' --tlsv1.2 -o "$checksums.part" "$base/download/v$version/SHA256SUMS" 2>/dev/null; then
    mv "$checksums.part" "$checksums"
    expected=$(awk -v name="$archive" '$2 == name || $2 == "*" name { print $1; exit }' "$checksums")
    [ -n "$expected" ] || fail "SHA256SUMS has no entry for $archive"
    if command -v sha256sum >/dev/null 2>&1; then actual=$(sha256sum "$output" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then actual=$(shasum -a 256 "$output" | awk '{print $1}')
    else fail "SHA256SUMS is available but no SHA-256 tool was found"
    fi
    [ "$actual" = "$expected" ] || fail "checksum mismatch for $archive"
    rm -f "$checksums"
    printf 'Verified SHA-256 for %s\n' "$archive" >&2
else
    rm -f "$checksums.part"
    printf 'strut download: SHA256SUMS is not published for v%s; downloaded over verified HTTPS without an explicit checksum\n' "$version" >&2
fi

printf '%s\n' "$output"
