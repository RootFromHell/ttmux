#!/bin/bash
# Install / uninstall TurboTmux: ttbars, ttmux; metrics example in share
# No args / -h: print usage
# Local:  sudo ./installer.sh --install [/prefix]
#         sudo ./installer.sh --uninstall [/prefix]
# Online: curl -fsSL https://github.com/RootFromHell/ttmux/raw/main/installer.sh | sudo bash -s -- --online
#         curl -fsSL https://github.com/RootFromHell/ttmux/raw/main/installer.sh | sudo bash -s -- --uninstall
set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"
DO_INSTALL=0
ONLINE=0
UNINSTALL=0
REINSTALL=0   # -uninstall_install: wipe then install (dev; not in --help)
UPGRADE_CONFIG=0  # --upgrade+config: --online + bar_parameters[] → cpu=/df=/… (dev; not in --help)
# Override branch/tag: TTMUX_RAW=https://github.com/RootFromHell/ttmux/raw/v1.0
TTMUX_RAW="${TTMUX_RAW:-https://github.com/RootFromHell/ttmux/raw/main}"

# TTY styles — ${_b}dir/${r_}${_green|_bblue|_c172|_bblack}name${r_}; URLs=_c32
_b=$'\e[1;38;5;250m'; _d=$'\e[2m'   # bold≈white grey 250; dim
_red=$'\e[31m'; _green=$'\e[32m'; _blue=$'\e[34m'; _bblue=$'\e[94m'; _magenta=$'\e[35m'
_bblack=$'\e[90m'                  # cache/junk *.state*
_c172=$'\e[38;5;172m'; _c32=$'\e[38;5;32m'   # man *.gz; URLs
r_=$'\e[0m'
[[ -t 1 ]] || { _b=; _d=; _red=; _green=; _blue=; _bblue=; _magenta=; _bblack=; _c172=; _c32=; r_=; }

# path for messages: dir=_b; basename by type; dirs keep trailing /
_ttmux_cpath() {
    local p=$1 base dir is_dir=0
    [[ "$p" == */ ]] && { p=${p%/}; is_dir=1; }
    [[ -d "$p" ]] && is_dir=1
    if (( is_dir )); then
        printf '%s%s/%s' "$_b" "$p" "$r_"
        return
    fi
    base=${p##*/}
    dir=${p%"$base"}
    case "$base" in
        ttbars|ttmux)
            if [[ "$dir" == */bin/ ]]; then
                printf '%s%s%s%s%s%s' "$_b" "$dir" "$r_" "$_green" "$base" "$r_"
            else
                printf '%s%s%s' "$_b" "$p" "$r_"
            fi
            ;;
        *.conf|*.conf.*|*.bak|.bashrc)
            printf '%s%s%s%s%s%s' "$_b" "$dir" "$r_" "$_bblue" "$base" "$r_"
            ;;
        *.1|*.1.gz|*.gz)
            printf '%s%s%s%s%s%s' "$_b" "$dir" "$r_" "$_c172" "$base" "$r_"
            ;;
        *.state|*.state.*|*.lock)
            printf '%s%s%s%s%s%s' "$_b" "$dir" "$r_" "$_bblack" "$base" "$r_"
            ;;
        *)
            printf '%s%s%s' "$_b" "$p" "$r_"
            ;;
    esac
}

usage() {
    # curl | bash -s → $0 is "bash"; always show the public name
    local me=installer.sh
    echo "ℹ️ Usage:"
    echo "   sudo ${_b}./${r_}${_green}$me${r_} --install         ${_bblack}# local install from this tree (${r_}$(_ttmux_cpath /usr/local/)${_bblack})${r_}"
    echo "   sudo ${_b}./${r_}${_green}$me${r_} --install ${_b}/usr${r_}    ${_bblack}# local, different prefix${r_}"
    echo "   sudo ${_b}./${r_}${_green}$me${r_} ${_b}/usr${r_}              ${_bblack}# same as --install /usr${r_}"
    echo "   sudo ${_b}./${r_}${_green}$me${r_} --online          ${_bblack}# download install files from ${r_}${_c32}GitHub${r_}${_bblack}, then install${r_}"
    echo "   sudo ${_b}./${r_}${_green}$me${r_} --online ${_b}/usr${r_}"
    echo "   sudo ${_b}./${r_}${_green}$me${r_} --uninstall       ${_bblack}# wipe install, ${r_}${_bblue}ttmux.conf${r_}${_bblack}, cache (keeps ${r_}${_bblue}ttbars.conf${r_}${_bblack})${r_}"
    echo "   sudo ${_b}./${r_}${_green}$me${r_} --uninstall ${_b}/usr${r_}"
    echo
    echo "🌐 Running the installer from the network:"
    echo "   curl -fsSL ${_c32}${TTMUX_RAW}/${r_}${_green}installer.sh${r_} | sudo bash -s -- --online"
    echo "   curl -fsSL ${_c32}${TTMUX_RAW}/${r_}${_green}installer.sh${r_} | sudo bash -s -- --uninstall"
    echo "   curl -fsSL ${_c32}${TTMUX_RAW}/${r_}${_green}installer.sh${r_} | sudo bash -s -- --uninstall ${_b}/usr${r_}"

    echo
    echo "🗑️ Removes: ${_b}\$PREFIX/bin/${r_}${_green}{ttbars,ttmux}${r_}, man pages, share example;"
    echo "         ${_b}~/.config/${r_}${_bblue}ttmux.conf${r_} + ${_bblack}cache${r_} (invoking user under sudo)."
    echo "         Keeps user/system ${_bblue}ttbars.conf${r_} (users create those)."
}

for arg in "$@"; do
    case "$arg" in
        -h|--help) usage; exit 0 ;;
        --install) DO_INSTALL=1 ;;
        --online) ONLINE=1; DO_INSTALL=1 ;;
        --uninstall) UNINSTALL=1 ;;
        -uninstall_install|--uninstall_install) REINSTALL=1; DO_INSTALL=1 ;;
        -upgrade+config|--upgrade+config) UPGRADE_CONFIG=1; ONLINE=1; DO_INSTALL=1 ;;
        /*) PREFIX=$arg; DO_INSTALL=1 ;;
        *) echo "❌ Unknown argument: $arg" >&2; usage; exit 1 ;;
    esac
done

# no action → help
if (( ! DO_INSTALL && ! UNINSTALL && ! REINSTALL )); then
    usage
    exit 0
fi

BINDIR="${BINDIR:-$PREFIX/bin}"
SHAREDIR="${SHAREDIR:-$PREFIX/share/ttmux}"
MANDIR="${MANDIR:-$PREFIX/share/man/man1}"

[[ $EUID -eq 0 ]] || { echo "For system install/uninstall: sudo ./installer.sh --install|…" >&2; exit 1; }

# sudo → calling user's home (not /root)
_ttmux_user_home() {
    if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]]; then
        getent passwd "$SUDO_USER" | cut -d: -f6
    else
        printf '%s' "$HOME"
    fi
}

# bar_parameters=("cpu|CPU|c|10" …) → cpu="CPU|c|10"; df_usage| → df=
_ttmux_upgrade_bar_parameters() {
    local conf=$1 out line body tail id rest in_arr=0 n=0
    [[ -r "$conf" ]] || return 0
    grep -q 'bar_parameters=(' "$conf" || {
        echo "🔍 $(_ttmux_cpath "$conf") — no bar_parameters"
        return 0
    }
    out=$(mktemp)
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^[[:space:]]*bar_parameters=\( ]]; then
            in_arr=1
            continue
        fi
        if (( in_arr )); then
            if [[ "$line" =~ ^[[:space:]]*\)[[:space:]]*$ ]]; then
                in_arr=0
                continue
            fi
            # drop array indent; keep trailing comment as-is
            if [[ "$line" =~ ^[[:space:]]*\"([^\"]+)\"(.*)$ ]]; then
                body=${BASH_REMATCH[1]}
                tail=${BASH_REMATCH[2]}
                id=${body%%|*}
                rest=${body#*|}
                [[ "$id" == df_usage ]] && id=df
                printf '%s="%s"%s\n' "$id" "$rest" "$tail"
                n=$((n + 1))
                continue
            fi
            continue
        fi
        printf '%s\n' "$line"
    done <"$conf" >"$out"
    cp -a "$conf" "${conf}.bak"
    mv "$out" "$conf"
    echo "🔧 $(_ttmux_cpath "$conf") — $n bars → cpu=/df=/… (backup $(_ttmux_cpath "${conf}.bak"))"
}

# Old hosts: giant alias ttmux="tmux attach … || tmux new-session …" in ~/.bashrc
_ttmux_strip_bashrc_ttmux_alias() {
    local home bashrc out line skip=0 owner
    home=$(_ttmux_user_home)
    bashrc="$home/.bashrc"
    [[ -r "$bashrc" ]] || return 0
    grep -qE '^[[:space:]]*alias[[:space:]]+ttmux=' "$bashrc" || {
        echo "🔍 $(_ttmux_cpath "$bashrc") — no alias ttmux"
        return 0
    }
    out=$(mktemp)
    while IFS= read -r line || [[ -n "$line" ]]; do
        if (( skip )); then
            [[ "$line" =~ \\[[:space:]]*$ ]] || skip=0
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+ttmux= ]]; then
            [[ "$line" =~ \\[[:space:]]*$ ]] && skip=1
            continue
        fi
        printf '%s\n' "$line"
    done <"$bashrc" >"$out"
    cp -a "$bashrc" "${bashrc}.bak"
    mv "$out" "$bashrc"
    if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]]; then
        owner=$(stat -c '%u:%g' "$home" 2>/dev/null) || owner="$SUDO_USER:"
        chown "$owner" "$bashrc" "${bashrc}.bak"
        sudo -u "$SUDO_USER" -H bash -c 'source "$HOME/.bashrc"' </dev/null || true
    else
        # shellcheck disable=SC1090
        bash -c 'source "$1"' bash "$bashrc" </dev/null || true
    fi
    echo "🔧 $(_ttmux_cpath "$bashrc") — removed alias ttmux=… (backup $(_ttmux_cpath "${bashrc}.bak"); sourced)"
    echo "🔄 Current shell still has the old alias — run: unalias ttmux 2>/dev/null; source $(_ttmux_cpath "$bashrc")"
}

_ttmux_do_uninstall() {
    local user_home user_cfg user_cache f
    user_home=$(_ttmux_user_home)
    user_cfg="$user_home/.config"
    user_cache="$user_home/.cache"

    for f in \
        "$BINDIR/ttbars" "$BINDIR/ttmux" \
        "$SHAREDIR/ttbars.conf.example"
    do
        [[ -e "$f" || -L "$f" ]] || continue
        rm -f "$f"
        echo "🗑️  $(_ttmux_cpath "$f")"
    done
    if [[ -d "$SHAREDIR" ]] && rmdir "$SHAREDIR" 2>/dev/null; then
        echo "🗑️  $(_ttmux_cpath "${SHAREDIR%/}/")"
    fi
    for f in \
        "$MANDIR/ttmux.1" "$MANDIR/ttmux.1.gz" "$MANDIR/ttbars.1" "$MANDIR/ttbars.1.gz" \
        "$user_cfg/ttmux.conf" \
        "$user_cache/ttbars.state" "$user_cache/ttbars.state.lock"
    do
        [[ -e "$f" || -L "$f" ]] || continue
        rm -f "$f"
        echo "🗑️  $(_ttmux_cpath "$f")"
    done
}

if (( UNINSTALL && ! REINSTALL )); then
    _ttmux_do_uninstall
    exit 0
fi
if (( REINSTALL )); then
    _ttmux_do_uninstall
fi

_ttmux_fetch() {
    local url=$1 dest=$2
    if command -v curl &>/dev/null; then
        curl -fsSL "$url" -o "$dest"
    elif command -v wget &>/dev/null; then
        wget -qO "$dest" "$url"
    else
        echo "❌ Need curl or wget for --online" >&2
        exit 1
    fi
}

if (( ! ONLINE )); then
    ROOT="$(cd "$(dirname "$0")" 2>/dev/null && pwd)" || ROOT=""
    if [[ -n "$ROOT" && -r "$ROOT/ttbars" && -r "$ROOT/ttmux" ]]; then
        :
    elif (( REINSTALL )); then
        # curl | bash -uninstall_install: no local tree → fetch like --online
        ONLINE=1
    else
        echo "❌ Local tree not found (ttbars/ttmux). Use --online or run from the repo." >&2
        exit 1
    fi
fi

if (( ONLINE )); then
    ROOT=$(mktemp -d)
    trap 'rm -rf "$ROOT"' EXIT
    mkdir -p "$ROOT/share/ttmux" "$ROOT/man"
    echo "⬇️ Fetching from ${_c32}$TTMUX_RAW${r_} …"
    _ttmux_fetch "$TTMUX_RAW/ttbars" "$ROOT/ttbars"
    _ttmux_fetch "$TTMUX_RAW/ttmux" "$ROOT/ttmux"
    _ttmux_fetch "$TTMUX_RAW/share/ttmux/ttbars.conf.example" "$ROOT/share/ttmux/ttbars.conf.example"
    _ttmux_fetch "$TTMUX_RAW/man/ttmux.1" "$ROOT/man/ttmux.1"
    _ttmux_fetch "$TTMUX_RAW/man/ttbars.1" "$ROOT/man/ttbars.1"
    chmod +x "$ROOT/ttbars" "$ROOT/ttmux"
fi

# tmux required, mc optional (default right pane) — only what's missing
_ttmux_ensure_deps() {
    local need=()
    command -v tmux &>/dev/null || need+=(tmux)
    command -v mc &>/dev/null || need+=(mc)
    ((${#need[@]})) || return 0
    echo "📦 Installing packages: ${_green}${need[*]}${r_}"
    if command -v apt-get &>/dev/null; then
        apt-get update -qq
        DEBIAN_FRONTEND=noninteractive apt-get install -y "${need[@]}"
    elif command -v dnf &>/dev/null; then
        dnf install -y "${need[@]}"
    elif command -v apk &>/dev/null; then
        apk add --no-cache "${need[@]}"
    elif command -v pacman &>/dev/null; then
        pacman -Sy --noconfirm "${need[@]}"
    else
        echo "⚠️ Install manually: ${need[*]}" >&2
    fi
}
_ttmux_ensure_deps

install -d "$BINDIR" "$SHAREDIR" "$MANDIR"
install -m 755 "$ROOT/ttbars" "$ROOT/ttmux" "$BINDIR/"
install -m 644 "$ROOT/share/ttmux/ttbars.conf.example" "$SHAREDIR/"
for manpage in ttmux.1 ttbars.1; do
    if [[ -r "$ROOT/man/$manpage" ]]; then
        install -m 644 "$ROOT/man/$manpage" "$MANDIR/"
        gzip -nf "$MANDIR/$manpage"
    fi
done
echo "✅ Installed: $(_ttmux_cpath "$BINDIR/ttbars")  $(_ttmux_cpath "$BINDIR/ttmux")"
echo "📝 Metrics example: $(_ttmux_cpath "$SHAREDIR/ttbars.conf.example")"
echo "   can be placed in $(_ttmux_cpath /etc/ttbars.conf) or $(_ttmux_cpath "$(_ttmux_user_home)/.config/ttbars.conf")"
echo "📝 ttmux config: $(_ttmux_cpath "$(_ttmux_user_home)/.config/ttmux.conf") automatically created on first ${_green}ttmux${r_} run"

if (( UPGRADE_CONFIG )); then
    _ttmux_upgrade_bar_parameters /etc/ttbars.conf
    _ttmux_upgrade_bar_parameters "$(_ttmux_user_home)/.config/ttbars.conf"
    _ttmux_strip_bashrc_ttmux_alias
fi
