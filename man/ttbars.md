% TTBARS(1) ttbars | User Commands
%
% July 2026

<!-- ver: 0+1🆙 # 🚀 TurboTmux: project started -->

# NAME

ttbars - minimalist resource monitor with pseudographic bars

# SYNOPSIS

**ttbars** \[**-tmux**|**-tty**|**-plain**\] \[**-t** \[*interval*\]\] \[**-c**|**-cm**|**-cd**|**-cs**\] \[**-v**|**\-\-version**\]

# DESCRIPTION

**ttbars** is a minimalist system monitor. It prints key resources as pseudographic bars: CPU, RAM, DISK, ZFS, Btrfs, and network ↑ TX / ↓ RX. Use it for a one-shot dump, as a continuous terminal monitor, or as a **tmux**(1) status-line plugin.

**ZFS** and **Btrfs** bars appear only if pools or volumes are found.

The network bar can indicate light traffic in two ways: a more noticeable label change, or a brief boost of the first scale segment on small rare packets. That feature only makes sense with a small *measure_interval_sec*.

# OPTIONS

**-t** \[*interval*\]
:   Watch mode: redraw in a loop. Optional *interval* (seconds, default 1) sets *measure_interval_sec* and overrides the config. Example: **ttbars -t 1**.

**-c**, **-cm**, **-cd**, **-cs**
:   Color palette demo (*colour1*–*colour255* and named colors). **-c** random labels, fixed bar; **-cm** compact: numbers / color names only; **-cd** random labels/fill with matched symbol pairs; **-cs** random symbols independently.

**-tmux**
:   Output for the tmux status line. Syncs *measure_interval_sec* with tmux *status-interval* when available.

**-tty**
:   Terminal output (ANSI colors). In tty mode bars wrap by whole groups to the terminal width.

**-plain**
:   Plain output without tmux/tty markup.

**-v**, **\-\-version**
:   Print version and exit.

With no format flag, the mode is chosen automatically (tmux when appropriate, otherwise tty).

# USAGE

One-shot dump:

```
ttbars
```

Continuous refresh every second (`-t` without a number also uses 1 s):

```
ttbars -t 1
```

As a tmux plugin in *~/.tmux.conf* (or TurboTmux *~/.config/ttmux.conf*):

```
set -g status-left '#(ttbars -tmux)'
set -g status-interval 1
set -g status-left-length 100
```

# CONFIGURATION

Metrics config may be system-wide or per-user. User config overrides system:

*/etc/ttbars.conf*
:   All users.

*~/.config/ttbars.conf*
:   Personal overrides.

Example template after install: */usr/local/share/ttmux/ttbars.conf.example*. You can also set variables at the top of the **ttbars** script instead of using a config file.

## Appearance

Bar symbols:

```
S1="▪"          # filled segment       ▪ ▪ ▮ ◉ ▓ • # ▪
S0="·"          # empty segment        · ▫ ▯ ◯ ░ ∘ · -
```

Labels, colors, and length — configured via variables *id="label|color|length"*

```
cpu="CPU|colour160|10"
ram="RAM|green|10"
df="|cyan|5"              # empty label = per-volume names (*_labels or auto); non-empty = group title
zfs="|brightblue|5"
btrfs="|brightmagenta|5"
net_tx="↑,▲|yellow|nano"   # Second label for net_led_label_blink=on
net_rx="↓,▼|colour151|nano"
```

Colors are standard colors or index 1-256 (red, green, cyan, brightblue, 214/c214/color214/colour214 etc.). Color palette demo: **ttbars -c** (or **-cm** / **-cd** / **-cs**).

Length is a segment count, or *nano* — a minimalist one-cell eight-level scale ⢀⢠⢰⢸⣸⣼⣾⣿.

df, ZFS and Btrfs: empty appearance label → per-volume text from *df_labels* / *zfs_labels* / *btrfs_labels* (or auto names). Non-empty label (e.g. *DISKS*) → group title; with empty *\*_labels* the bars are bare; if *\*_labels* is set — title and per-volume labels together.

## DISK

By default real mounts are shown (block disks, ZFS datasets, NFS, …; no loop/tmpfs). You can filter the list and set short labels:

```
df_usage="/,/var"        # empty = all real mounts except df_exclude; else CSV
df_labels="ROOT,DATA"    # empty = mount names (/, → root)
df_exclude="/boot,ds.*"  # hidden mount points list; simple patterns ok
```

## ZFS

```
zfs_pools="zfs-pool,zfs-backup"   # empty = all except zfs_exclude
zfs_labels="DATA,BACKUP"
zfs_exclude="rpool,test*"         # hidden pools list
```

## Btrfs

```
btrfs_mounts="/mnt/data,/mnt/backup"
btrfs_labels="DATA,BACKUP"
btrfs_exclude="/boot,ds.*"        # hidden mount points list
```

## Network

```
interface=""             # empty = auto-detect
net_max_speed="1000"     # Mbps scale; empty = auto (fallback 100)
net_led_bytes="512"      # light-traffic threshold (bytes per sample)
net_led_bar_boost=on
net_led_label_blink=off
```

## Polling and cache

*measure_interval_sec* is the window over which stats are collected and averaged (default 1 s in console). Override via config or **-t**. In plugin mode it syncs with tmux *status-interval*.

```
measure_interval_sec=1
measure_deadline_ratio_pct=100
```

**ttbars** caches results between runs. Prefer longer refresh for disks and shorter for fast metrics like CPU:

```
cpu_refresh_sec=0.1
ram_refresh_sec=1
df_refresh_sec=30
zfs_refresh_sec=30
btrfs_refresh_sec=30
net_refresh_sec=0.1
```

# FILES

*/etc/ttbars.conf*
:   System metrics settings.

*~/.config/ttbars.conf*
:   Personal metrics settings (overrides */etc*).

*/usr/local/share/ttmux/ttbars.conf.example*
:   Example metrics config after install.

*~/.cache/ttbars.state*
:   Metrics cache between ticks.

*~/.cache/ttbars.state.lock*
:   Lock while updating the cache.

# TROUBLESHOOTING

Empty network bars — check auto-detection with **grep interface ~/.cache/ttbars.state**, then set manually if needed:

```
interface="vmbr0"
net_max_speed="100"
```

On some physical terminals, default bar symbols are the most reliable: *S1="▪"*, *S0="·"*.

# AUTHORS

**VladList** — https://github.com/RootFromHell/ttmux

# SEE ALSO

**ttmux**(1), **tmux**(1)
