% TTMUX(1) TurboTmux | User Commands
%
% July 2026

<!-- ver: 0+1🆙 # 🚀 TurboTmux: project started -->

# NAME

ttmux - TurboTmux session launcher and environment

# SYNOPSIS

**ttmux** \[**-v**|**\-\-version**\]

# DESCRIPTION

**ttmux** is a simple launcher for **tmux**(1). It runs without replacing tmux and does not touch *~/.tmux.conf*. Settings live in *~/.config/ttmux.conf*. You can use TurboTmux side by side with ordinary tmux.

Invoking **ttmux** with no arguments attaches to an existing session named *ttmux*, or creates one if none exists. The new session uses a three-pane layout. No flags or session names are required.

Out of the box TurboTmux offers a ready three-pane terminal layout, mouse control, clipboard, and the **ttbars**(1) plugin for a status line with a monitor of key resources as pseudographic bars (CPU, RAM, DISK, ZFS, Btrfs, network ↑ TX / ↓ RX).

TurboTmux is still almost entirely tmux. A small set of hotkeys is usually enough (default prefix **Ctrl+b**, then the key):

**Ctrl+b**, **d**
:   Detach from the session. **ttmux** keeps running in the background; the terminal returns to a normal shell.

**Ctrl+b**, **z**
:   Zoom the current pane to full screen / restore previous size.

**Ctrl+b**, **&**, **y**
:   Close the current session (tmux asks for confirmation).

Optional dependency: **mc**(1) (launched in the right pane by default).

# OPTIONS

**-v**, **\-\-version**
:   Print version and exit.

# CONFIGURATION

On first start, if missing, **ttmux** creates *~/.config/ttmux.conf*. It holds basic tmux settings (mouse, clipboard, colors, status line) and TurboTmux layout parameters. The file is created once and is not overwritten.

Layout variables (empty command = interactive shell; *ttmux_pane_right_run* defaults to **mc** if installed):

```
ttmux_pane_left_run=''
ttmux_pane_right_run='mc'
ttmux_pane_bottom_run='cd /my/project'
ttmux_pane_right_width_pct=70
ttmux_pane_bottom_height=1
```

If *~/.config/mc/* is missing, **ttmux** also creates an mc config: dark skin and arrow-key navigation.

The status line includes **ttbars** in plugin mode:

```
set -g status-left '#(ttbars -tmux)'
set -g status-interval 1
```

Edit later with a text editor, e.g. **nano** *~/.config/ttmux.conf*.

If mouse selection fails on some systems, comment out mouse support in that file:

```
# set -g mouse on
```

ℹ️ manage **tmux** panes with hotkeys:

| Keys | Action |
|------|--------|
| **Ctrl+b**, **↑**/**↓**/**←**/**→** | switch pane |
| **Ctrl+b**, **Alt**+**↑**/**↓**/**←**/**→** | resize the current pane |

# FILES

*~/.config/ttmux.conf*
:   tmux config and layout for TurboTmux.

*~/.config/mc/*
:   Also created by **ttmux** if missing (dark skin, arrow keys); never overwritten.

*~/.config/ttbars.conf*
:   Personal metrics settings for **ttbars**(1).

*/etc/ttbars.conf*
:   System metrics settings for **ttbars**(1).

# AUTHORS

**VladList** — https://github.com/RootFromHell/ttmux

# SEE ALSO

**ttbars**(1), **tmux**(1), **mc**(1)
