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
  of cpu, memory, temperature and battery (click cpu or mem for the heaviest processes,
  sorted by it; the column headings switch the sort; click one to end it, or kill it if it
  will not go; click displays for the monitors, below).
- **Launcher** — a key (see below) grows the island on the screen you are on into a search
  field over your apps. Type to filter by name, generic name, keywords or initials ("vsc");
  up and down pick, Enter launches, Escape or a click outside closes. With nothing typed
  the apps are in alphabetical order; once you type, among equal matches the apps you launch
  most come first.
- **Volume pill** — when the volume changes (the volume and mute keys, or anything else
  that turns the output up, down or off), the island drops down with the level for a
  moment, on the screen you are on. Not while the dashboard is open, whose slider shows it.
- **Brightness pill** — the same for the brightness: the brightness keys (5% a press, see
  below), or anything else that changes the backlight. 0% is the dimmest the screen goes,
  never off.

Close it with a click outside, or Escape once you've clicked anything inside it (the
dashboard only takes the keyboard on a click, so a workspace switch while it's open
moves focus normally). It also closes itself after 30 s without the pointer on it.

Log out, reboot and power off ask for a second click within 3 s. Lock does not.

### Displays

`displays`, at the right of the dashboard's bottom line, opens the monitors plugged in: a
map of where they sit, and the modes of the one picked on it. Drag a monitor on the map
and drop it beside another: it snaps to touch that one's side, lining up with its edges
or middle when dropped near them. Click a mode to switch to it. A new mode goes back to
the old one after 15 s unless you click keep, so a mode the screen cannot show undoes
itself.

Changes take effect at once and are saved to `~/.config/hypr/monitors.lua`, one line per
monitor, named by its description so the setting follows it to another port. A monitor
not plugged in keeps its line. The pane rewrites that file whole, so anything else about a
monitor (vrr, bit depth) belongs in `hyprland.lua`.

### Lock screen

A dark frosted screen, opaque: a big clock and the date in the top corner, the password
as a terminal prompt in the bottom one (`el_scrondo ❯ password:`, coloured like the zsh
prompt), and battery, wifi and caps lock across from it. Type the password and press
Enter; Escape empties the prompt. It checks the password the way logging in does
(PAM's `login`), so three wrong tries lock the account for ten minutes, as at the login
prompt.

It runs as its own instance, apart from the shell, which hypridle starts. In
`~/.config/hypr/hypridle.conf`:

```
lock_cmd = qs -p ~/.config/quickshell/dilico/lock.qml -n -d
inhibit_sleep = 3
```

The idle timer, the dashboard's lock button and suspend all lock through that line.
`inhibit_sleep = 3` keeps the machine awake until the lock screen is up. Without it,
suspend wins the race against Quickshell starting, and waking shows the desktop for a
moment before the lock appears.

If the lock screen ever crashes, the session stays locked with nothing to type into.
With `misc:allow_session_lock_restore` on in Hyprland, switch to a text console
(Ctrl+Alt+F3), log in, and start it again:

```sh
hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("qs -p ~/.config/quickshell/dilico/lock.qml -n -d")'
```

then switch back (Ctrl+Alt+F1, or whichever console Hyprland is on) and unlock.

## Requirements

- quickshell 0.3.1+, Qt 6
- Hyprland, PipeWire, NetworkManager, BlueZ, UPower with power-profiles-daemon
- `brightnessctl`, `udevadm`, `gdbus`, `loginctl`, `systemctl`
- JetBrainsMono Nerd Font
- An icon theme for app icons; `shell.qml` names it (`Adwaita`) in its `IconTheme` pragma

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

The launcher opens from a key Hyprland hands the shell:

```lua
hl.bind(mainMod .. " + SPACE", hl.dsp.global("quickshell:launcher"))
```

The brightness keys too, so they step 5% at a time on the same scale as the slider, and bring
the pill down:

```lua
hl.bind("XF86MonBrightnessUp",   hl.dsp.global("quickshell:brightness-up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.global("quickshell:brightness-down"), { locked = true, repeating = true })
```

The shell animates itself; the compositor animating the same surface makes it jitter:

```lua
hl.layer_rule({
    name    = "quickshell-dilico-no-anim",
    match   = { namespace = "^quickshell:dilico$" },
    no_anim = true,
})
```

Monitors come from the file the displays pane writes. In `hyprland.lua`, in place of
`hl.monitor` calls:

```lua
local monitors = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/monitors.lua"
if not pcall(dofile, monitors) then
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "1" })
end
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

To work on the lock screen without locking, show it in an ordinary window, and close it
from a terminal:

```sh
DILICO_LOCK_PREVIEW=1 qs -p lock.qml -d
qs kill -p lock.qml
```

`.qmlls.ini` is host-specific (it names this machine's uid and shell id); Quickshell
fills it in when it exists and is empty.

## Layout

```
shell.qml                          a layer-shell window per screen, its mask, the reveal
                                   and hold
lock.qml                           the lock screen, run as its own instance
components/                        Label, Subtext, Caption, Pressable, Surface,
                                   IconButton, TextButton, ChevronButton, Tile, Switch, Slider,
                                   Track, SignalBars, Segmented, TextField, Watch
config/                            Appearance, Colors, Typography, Rounding, Spacing,
                                   Animations, Glyphs
services/                          Apps, Audio, Auth, Battery, Bluez, Brightness,
                                   Compositor, Displays, Idle, Keyboard, Media, Network,
                                   Notifications, PowerMode, Processes, Radios, Session,
                                   SystemStats
utils/                             Icons, Format, Order, Calendar, Search, Arrange,
                                   MonitorRules
tests/                             offscreen tests and their runner
modules/island/Island.qml          the pill, the morph, the fillets, the backdrop
modules/island/panels/             Dashboard, Launcher
modules/island/components/         the island's own widgets
modules/lock/                      the lock screen, its frost and its prompt
docs/quickshell-conventions.md     where new code goes, and why
```
