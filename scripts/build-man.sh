#!/bin/bash
# man/ttmux.md → man/ttmux.1, man/ttbars.md → man/ttbars.1 (pandoc).
# Preview: man -l man/ttmux.1
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

[[ "${1:-}" == -h || "${1:-}" == --help ]] && {
    echo "Usage: $0              # build man/ttmux.1 and man/ttbars.1"
    echo "       $0 ttmux|ttbars # one page only"
    exit 0
}

command -v pandoc &>/dev/null || { echo "Need pandoc: apt install pandoc" >&2; exit 1; }

build_one() {
    local name=$1
    local src="$ROOT/man/${name}.md"
    local out="$ROOT/man/${name}.1"
    [[ -r "$src" ]] || { echo "Missing $src" >&2; return 1; }
    pandoc "$src" -s -t man -o "$out"
    echo "$out  →  man -l $out"
}

case "${1:-}" in
    "")
        build_one ttmux
        build_one ttbars
        ;;
    ttmux|ttbars)
        build_one "$1"
        ;;
    *)
        echo "Unknown argument: $1" >&2
        exit 1
        ;;
esac
