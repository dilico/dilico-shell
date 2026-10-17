# dilico

A [Quickshell](https://quickshell.org) top island for Hyprland. Hidden until the pointer
touches the top edge; then a small black clock drops down. Click it and it grows into a
dashboard. Every monitor has its own, which shows and opens independently of the others.

Two shapes, chosen by `attached` in `config/Appearance.qml`: a floating pill, rounded
all round and `gaps_out` below the edge (`false`, the default), or a notch that hangs
from the edge and flares into it (`true`).

- **Clock pill** — day, time, wifi, battery, and a dot when notifications are waiting.
- **Dashboard** — big clock and date (click either for the month, with today marked and
  arrows to the months either side); lock, log out, reboot, power off; network,
  bluetooth, keep-awake and airplane toggles (the `>` on network lists nearby networks
  by strength, with their security and signal: join one, with a password if it asks;
  a saved one opens details — internet status, access points, last used, auto-join,
  disconnect, forget; the `>` on bluetooth lists devices with their kind and battery:
  connect one, pairing it first if new, or open a paired one's details — address,
  connect automatically, disconnect, forget); volume, microphone and brightness sliders
  (the icon beside a slider mutes it; the `>` on volume and microphone lists the outputs
  or inputs with something plugged in, to switch to another); power profile; now playing; notifications; a line
  of cpu, memory, temperature and battery.
- **Volume pill** — when the volume changes (the volume and mute keys, or anything else
  that turns the output up, down or off), the island drops down with the level for a
  moment, on the screen you are on. Not while the dashboard is open, whose slider shows it.

Close it with a click outside, or Escape once you've clicked anything inside it (the
dashboard only takes the keyboard on a click, so a workspace switch while it's open
moves focus normally). It also closes itself after 30 s without the pointer on it.

Log out, reboot and power off ask for a second click within 3 s. Lock does not.

## Requirements

- quickshell 0.3.1+, Qt 6
- Hyprland, PipeWire, NetworkManager, BlueZ, UPower with power-profiles-daemon
- `brightnessctl`, `loginctl`, `systemctl`
- JetBrainsMono Nerd Font

## Run

```sh
qs -c dilico
```

To start it with the session, in `~/.config/hypr/hyprland.lua`:

```lua
hl.exec_cmd("qs -c dilico -n -d")
```

### Notifications

dilico is a notification daemon: it owns `org.freedesktop.Notifications` while it runs,
so mako, dunst or anything else that wants that name cannot run at the same time. There
are no popups yet — notifications collect in the dashboard and the pill shows a dot.
Click one to dismiss it.

## Hyprland settings

The shell animates itself; the compositor animating the same surface makes it jitter:

```lua
hl.layer_rule({
    name    = "quickshell-dilico-no-anim",
    match   = { namespace = "^quickshell:dilico$" },
    no_anim = true,
})
```

## Development

Read [`docs/quickshell-conventions.md`](docs/quickshell-conventions.md) before adding
anything — the code is expected to match it. §6 marks the rules that were rewritten after
they failed, and §10 says why. QML hot-reloads on save, but check the log for a reload
after the save if a change does not show (§8):

```sh
qs log -c dilico --log-times
```

`qmllint` must be silent and `tests/run.sh` must pass before anything is called done; both are
in §3 of the conventions.

`.qmlls.ini` is host-specific (it names this machine's uid and shell id); Quickshell
fills it in when it exists and is empty.

## Layout

```
shell.qml                          a layer-shell window per screen, its mask, the reveal
                                   and hold
components/                        Label, Subtext, Caption, Pressable, Surface,
                                   IconButton, TextButton, ChevronButton, Tile, Switch, Slider,
                                   Track, SignalBars, Segmented, TextField, Watch
config/                            Appearance, Colors, Typography, Rounding, Spacing,
                                   Animations, Glyphs
services/                          Audio, Battery, Bluez, Brightness, Compositor, Idle,
                                   Media, Network, Notifications, PowerMode, Radios,
                                   Session, SystemStats
utils/                             Icons, Format, Order, Calendar
tests/                             offscreen tests and their runner
modules/island/Island.qml          the pill, the morph, the fillets, the backdrop
modules/island/panels/             Dashboard
modules/island/components/         the island's own widgets
docs/quickshell-conventions.md     where new code goes, and why
```
