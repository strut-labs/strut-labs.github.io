#!/bin/sh
set -eu

install_dir=${STRUT_INSTALL_DIR:-"$HOME/.local/opt/strut"}
bin_dir=${STRUT_BIN_DIR:-"$HOME/.local/bin"}
manifest="$install_dir/.strut-install-manifest"
case "$install_dir" in ""|/|"$HOME"|"$HOME/.local") printf 'strut uninstall: refusing unsafe install directory: %s\n' "$install_dir" >&2; exit 1 ;; esac
if [ ! -e "$install_dir" ] && [ ! -L "$bin_dir/strut" ]; then printf 'Strut is not installed at %s.\n' "$install_dir"; exit 0; fi
[ -f "$manifest" ] || { printf 'strut uninstall: no Strut installation manifest at %s; refusing removal\n' "$manifest" >&2; exit 1; }
grep -qx 'strut-install-v1' "$manifest" || { printf 'strut uninstall: invalid installation manifest\n' >&2; exit 1; }
grep -Fqx "install_dir=$install_dir" "$manifest" || { printf 'strut uninstall: manifest path mismatch\n' >&2; exit 1; }
printf 'Removing Strut installation: %s\n' "$install_dir"
if [ -L "$bin_dir/strut" ] && [ "$(readlink "$bin_dir/strut")" = "$install_dir/bin/strut" ]; then
    printf 'Removing Strut command link: %s\n' "$bin_dir/strut"
    rm "$bin_dir/strut"
fi
rm -rf "$install_dir"
printf 'Strut has been uninstalled.\n'
