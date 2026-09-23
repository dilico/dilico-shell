# dilico

A [Quickshell](https://quickshell.org) bar for Hyprland. A centred clock pill that expands
on hover into a row of icons, each opening its own panel.

- **Clock** — the resting pill, date and time.
- **Volume** — mute, slider, and a dropdown to switch audio output. Volume keys pop it up
  briefly as an OSD.
- **Network, battery, bluetooth** — icons only for now.

## Requirements

- quickshell 0.3.1+, Qt 6
- Hyprland
- PipeWire with WirePlumber (`pw-dump`, `wpctl`)
- JetBrainsMono Nerd Font — plain JetBrains Mono renders the icons as blank boxes

## Install

The directory name is the config name, so it has to land here:

```sh
git clone <this-repo> ~/.config/quickshell/dilico
qs -c dilico
```

Start it with the session, in `~/.config/hypr/hyprland.lua`:

```lua
hl.exec_cmd("qs -c dilico -d")
```

## Hyprland settings

The shell needs three things from the compositor.

Without the layer rule the pill jitters as it resizes:

```lua
hl.layer_rule({
    name    = "quickshell-bar-no-anim",
    match   = { namespace = "^quickshell:bar$" },
    no_anim = true,
})
```

Without `follow_mouse = 2` a panel can stay open after the pointer leaves it:

```lua
hl.config({ input = { follow_mouse = 2 } })
```

## Development

QML is interpreted and Quickshell hot-reloads on save — there is no build step.

```sh
quickshell log -n -p ~/.config/quickshell/dilico/shell.qml   # errors and warnings
qs -p ~/some/worktree                                        # run a branch side by side
```

`qmllint` must be silent before anything counts as done:

```sh
qmllint -I "$(ls -d /run/user/$UID/quickshell/vfs/*)" \
    shell.qml components/*.qml config/*.qml services/*.qml \
    modules/bar/*.qml modules/bar/panels/*.qml
```

`.qmlls.ini` is not committed — it names this host's uid and shell id. For the QML
language server, recreate it with the path from the command above:

```ini
[General]
no-cmake-calls=true
buildDir="/run/user/1000/quickshell/vfs/<shell-id>"
importPaths="/usr/bin:/usr/lib/qt6/qml"
```

## Layout

```
shell.qml                          the layer-shell window, its mask and exclusive zone
components/                        feature-agnostic widgets (Icon, Slider)
config/                            constants: Colors, Typography, Animations, Glyphs
services/                          system state singletons (Audio: PipeWire)
modules/bar/                       the bar surface
modules/bar/panels/                panels the bar hosts
docs/quickshell-conventions.md     where new code goes, and why
```

Read [`docs/quickshell-conventions.md`](docs/quickshell-conventions.md) before adding
anything — the code is expected to match it.
