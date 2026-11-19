#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$(readlink -f -- "$0")")"
godot_bin="${MOZCOLHEITA_GODOT:-${OPENACRE_GODOT:-${HOME}/.local/share/openacre-tools/Godot_v4.6-stable_linux.x86_64}}"
if [[ ! -x "$godot_bin" ]]; then godot_bin=godot; fi
exec "$godot_bin" --editor --path "$PWD" "$@"
