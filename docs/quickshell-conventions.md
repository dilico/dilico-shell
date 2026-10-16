# Code structure blueprint

How this shell is organised. Consult it whenever you are about to add a file, and when
you catch yourself unsure where something belongs.

Rules here are deliberate and binding. Where a rule comes from Quickshell itself it is
marked **[engine]** — those are not negotiable. Everything else is a house decision, and
section 10 records why. If a rule stops serving the code, change the rule here first,
then the code.

The code follows this document. There is no list of exceptions: if something in the tree
disagrees with a rule here, either the code is wrong and gets fixed, or the rule is wrong
and gets rewritten. Section 9 holds the things deliberately not built yet, each with the
condition that should revive it — those are decisions, not debts.

Where a rule has been rewritten after it failed, §6 says so and §10 records the failure that
forced it.

---

## 1. Where does this go?

Ask, in order, and stop at the first yes:

1. **Does it talk to the outside world** — PipeWire, D-Bus, the filesystem, a subprocess,
   the compositor? → `services/`, as a singleton.
2. **Is it a constant** — a colour, a duration, a glyph, a font size? → `config/`, as a
   singleton.
3. **Is it a pure function** — formatting a value, picking a glyph for a state — with no
   IO and no state of its own? → `utils/`, as a singleton.
4. **Could another feature reasonably use it, with no change?** → `components/`.
5. **Does it belong to exactly one feature?** → `modules/<feature>/`.
6. **Is it the window itself, or a pragma?** → `shell.qml`.

If two answers feel right, you are holding two things. Split it.

## 2. Directory contracts

```
shell.qml                   windows, pragmas, wiring — nothing else
components/                 feature-agnostic primitives
modules/<feature>/          one directory per surface
modules/<feature>/panels/   panels that surface hosts
services/                   singletons that own external state
config/                     singletons that own constants
utils/                      singletons of pure functions
tests/                      offscreen tests of components/, config/ and utils/
docs/                       this file
```

### `shell.qml`

Contains instance pragmas **[engine]**, the `PanelWindow`(s), their masks and exclusive
zones, and the instantiation of top-level feature modules. Nothing that could be tested or
reasoned about on its own belongs here.

It grows by roughly one block per surface. If it is growing for any other reason, the
thing that is growing belongs in a module.

### `components/`

Generic, reusable, and nearly all visual: `Label`, `Slider`, and anything else another
feature could adopt unchanged. The one non-visual kind is a small helper a feature
instantiates for a service's sake, like `Watch`, which is handed the service rather than
importing it.

**A file in `components/` must never import `qs.modules`.** This is the rule the whole
layout rests on — it is what keeps "reusable" honest. A component that needs to know
about volume is not a component; it is a feature widget, and it belongs in
`modules/<feature>/`.

Components take their behaviour through properties and report through signals. They never
read a service and never decide policy. `Slider` emits `moved(value)`; it does not know
that something will set a PipeWire volume.

**Anything clicked is a `Pressable`.** It owns the hover, the hand cursor and the tap, so
every control answers the pointer the same way; what is built on it only draws. A
`MouseArea` appears only where a `Pressable` cannot do the job: a backdrop and the catcher
over the surface it guards (§6), or a drag (`Slider`). Accessibility actions are wired
where the pointer is: `Pressable` answers a screen reader's press, so everything built on it
does.

**Text takes a role, not a size.** `Label` is body text, `Subtext` the dimmer second line
under it, `Caption` the smallest metadata. Override colour or weight where the text is
something else. A new size in `Typography` arrives together with the role component that
uses it; a glyph (`iconSize`) and the big clock (`clockSize`) are the only sizes set
directly.

### `modules/<feature>/`

One directory per feature — `bar/`, `volume/`, `brightness/`. A feature owns its layout,
its panel, and any widget too specific to promote. Subdivide with
`modules/<feature>/components/` once a feature grows its own private widgets.

A feature may import `qs.components`, `qs.config`, `qs.services`, `qs.utils`, and its own
directory. It
should not import another feature. Two features that need to talk share a service or are
coordinated by their common parent.

**A feature is a surface, not a subject.** The bar is a feature; volume is not. A panel
belongs to the surface that hosts it — `modules/bar/panels/VolumePanel.qml` — while the
domain it speaks for lives in `services/Audio.qml`. Splitting by subject instead produces
`modules/bar` importing `modules/volume`, which is the cross-feature import this rule
exists to prevent. The service is what the two share.

Feature-local singletons are fine (`modules/<feature>/services/`) when the state genuinely
belongs to that feature alone. Prefer this over growing the global `services/`.

### `services/`

Singletons that own external state: the audio sinks, the backlight, the network. A service
answers "what is true right now" and "make this true", and knows nothing about pixels.

A service must not:
- import `qs.components` or `qs.modules`
- contain an `Item`, a layout, or anything visual
- know which panel is displaying it

A service must:
- be a singleton (see §4)
- expose plain, typed, readable properties — `volume`, `muted`, `sinks`, `ready`
- expose typed functions for actions — `setVolume(v: real): void`
- absorb the vendor mess. Optional chaining against half-connected daemons, JSON parsing,
  subprocess polling, tracker objects — all of it lives here, so panels stay declarative.

**[engine]** A backend singleton connects on first use *by a binding* and fills in over the
seconds after that. Read one from plain JavaScript before anything has bound to it and it
reads empty forever, so a service exposes bindings, never snapshots.

**A service that polls counts its watchers.** It exposes `property int watchers` and polls
only while that is above 0; whatever shows the data holds a `Watch { service: … }` for as
long as it exists. A count, not a flag: two consumers can come and go in any order without
one switching off the other's polling. One reading at startup is not polling: a service
takes it when its first consumer would otherwise change shape as the first reading lands
(`Brightness` decides whether the dashboard has a row at all), and `shell.qml` forces the
singleton so the reading happens before anything is shown (§4).

**The backend's enums stop at the service.** Hand panels names of your own — `"saver"`,
`"balanced"` — or a predicate like `secured(network)`, so nothing outside `services/` ever
imports a `Quickshell.Services.*` module to say which thing it means.

The test: a fact a panel works out for itself — whether wifi is connected, whether both
radios are off — has leaked out of its service. How to *show* a fact is not a leak; `utils/`
below says where that goes.

### `config/`

Singletons of constants only, one per concern: `Colors`, `Typography`, `Animations`,
`Glyphs`. No logic, no state, no IO.

Every colour in the codebase comes from `Colors`. Every animation duration and easing from
`Animations`. Every font family and size from `Typography`. Every glyph from `Glyphs`. A
literal `"#98C379"`, `duration: 200`, or `""` anywhere else is a bug — one-off values
are how a theme stops being changeable in one place.

Two things are not theme and stay literal. `"transparent"` is the absence of a colour, not
a choice of one. A `Timer`'s interval — a hold, a timeout, a poll — is behaviour: it
belongs to whatever owns the timer, with a comment where the length is not obvious.

`Glyphs` entries are declared `String.fromCodePoint(0x…)`, never pasted characters or
surrogate pairs. Verify a codepoint by rendering it from the installed font before adding
it; the Nerd Fonts cheat sheets are wrong often enough to matter.

Sizes, radii and spacings are **not** config. A corner radius or a panel width is a
property of the thing that draws it, and belongs in that file. It graduates to `config/`
the moment a second file needs the same value *for the same reason* — at which point it is
shared design, not a local choice. Two cards side by side sharing an inner padding is that
(`Spacing.card`); two unrelated 12s are a coincidence and stay apart. Do not build a token
system in advance of that.

### `utils/`

Singletons of pure functions: `Icons` picks a glyph for a state, `Format` turns a number or
a date into text. Each function answers from its arguments alone — no IO, no state, no
reading a service — so the caller passes in what it shows:
`Icons.wifi(Network.connected, Network.strength)`. A util may import `qs.config` and
nothing else of ours.

In `modules/`, a binding makes at most one choice inline. Anything more is a function: in
`utils/` if it picks a glyph or a second file needs it, otherwise a named, typed function
or property in its own file (`bluetoothSubtitle()`), never a chain of ternaries.

## 3. Every file

Start every file with:

```qml
pragma ComponentBehavior: Bound   // if it contains a delegate or Component

import QtQuick
import Quickshell...              // Quickshell modules next
import qs.components              // then ours, alphabetically
import qs.config
import qs.services
import qs.utils
```

Import only what the file uses. Alphabetical rather than layered, because it is mechanical: there is never a question of
where a new import goes.

**[engine]** Import with `qs.<dir>`, never relative paths — relative imports are documented
as worse for tooling. JavaScript files are the exception and must be imported relatively.

**[engine]** Never write a `qmldir`. Quickshell synthesizes one per directory from
`pragma Singleton` and the filenames; a hand-written one disables that.

**[engine]** Only files whose names begin with an uppercase letter are exported. One type
per file, named as the file. Directories are lowercase.

Inside an object, keep this order, separated by blank lines:

1. `id`
2. property declarations, `readonly` ones included
3. `signal` declarations
4. functions
5. property bindings, including `implicitWidth`/`implicitHeight` and `on<Property>Changed`
   handlers
6. child objects — `Behavior`, handlers, `Timer`, `Connections`, visual children
7. `states` and `transitions`
8. inline `component` definitions

Declarations before use: a reader should meet a file's interface — what it takes, what it
emits, what it can do — before the machinery that implements it.

Type every function — parameters and return:

```qml
function shortName(node: var): string { ... }
function setVolume(v: real): void { ... }
```

`qmllint` must be silent. Run it before calling anything done:

```
qmllint -I "$(sed -n 's/^buildDir="\(.*\)"/\1/p' .qmlls.ini)" \
    shell.qml components/*.qml config/*.qml services/*.qml utils/*.qml \
    modules/*/*.qml modules/*/panels/*.qml modules/*/components/*.qml
```

The include path is only populated while `.qmlls.ini` exists; Quickshell fills an empty
one in on the next launch.

A `// qmllint disable <rule>` is allowed only for a verified false positive, on the
narrowest possible scope, with the reason in a comment.

`tests/run.sh` must pass too. It runs every `tests/tst_*.qml` offscreen in `qmltestrunner`,
against a throwaway `qs` tree it builds outside the config (so the no-`qmldir` rule still
holds) and a stand-in for Quickshell's `Singleton`. Only `components/`, `config/` and
`utils/` load that way: services and windows need the `qs` binary, so they are checked in
the running shell. A fix for a bug those three directories can show comes with a test that
fails without it — check that it does.

## 4. Singletons

**[engine]** `pragma Singleton` above the imports, and the root element is Quickshell's
`Singleton` type — not `QtObject`. `Singleton` inherits `Scope` and participates in live
reload correctly.

```qml
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root
    ...
}
```

Singletons are for things of which there is exactly one in the world: the audio system,
the palette. If writing `Foo { }` twice would be meaningful, it is a component, not a
singleton.

Be aware that a singleton nothing references may never be instantiated. A singleton that
must run at startup — one registering an IPC handler, a global shortcut, or a D-Bus name
such as the notification daemon — needs an explicit reference from a live object to force
it. `shell.qml` makes it in `Component.onCompleted`, with a comment naming the reason, so
removing some unrelated binding can never silently stop it.

**[engine]** Inside `services/`, refer to a sibling service through `import qs.services`
like anywhere else. The implicit same-directory import does not know the type is a
singleton.

## 5. Components take, never reach

A child never reaches up into its parent's ids or state. It declares what it needs:

```qml
required property ShellScreen modelData
required property var modelData
```

and the parent supplies it. This is what makes a component movable, and it is why
`pragma ComponentBehavior: Bound` is mandatory in any file containing a delegate — under
`Bound`, reaching upward fails loudly instead of silently binding to the wrong scope.

Data flows down through properties; events flow up through signals. A control does not
write the state it displays: `Slider` emits `moved`, and its owner decides whether that
becomes a volume change. This is what lets an external change — a media key, another app —
flow back into the same control without the two fighting.

## 6. Windows and panels

**One layer-shell `PanelWindow` per screen.** Panels are ordinary `Item`s inside it, never
windows of their own. A second window is justified only when the content must outlive or
escape the bar — a lock screen, a standalone settings window.

**[engine]** Every window sets an explicit `WlrLayershell.namespace`, per surface
(`quickshell:dilico`), so compositor rules can target one surface rather than everything.

**The window never resizes in response to interaction.** Its height is a constant ceiling
large enough for the tallest panel; the extra is transparent and masked out. Resizing a
layer surface hands the compositor a frame to animate or stretch, and the result is
visible jitter no amount of QML smoothing will fix.

**Input comes from the `mask` region**, bound to the geometry of what is actually visible.
Where an animated element drives the mask, the region must be a superset of both the
resting and expanded shapes, so it can never shrink out from under the pointer mid-animation.

**A surface that hides itself reserves nothing** (`exclusiveZone: 0`) and is called up by a
thin strip along the screen edge that stays in the mask at all times. Once it is up, the
mask adds the surface itself plus a small margin around it — not a taller band along the
whole edge, which would swallow every click on the tabs and title bars underneath for as
long as the surface shows. The travel from wherever the pointer touched the edge to the
surface is covered by the hold below, which is why that hold is long enough to cross the
screen. Every hover that drives the reveal is held past the pointer leaving; without that,
a boundary the pointer comes to rest on toggles. *(Rewritten from the first version's taller band.)*

**"Is the pointer here" is asked once, of the whole window.** The mask already says exactly
where the surface takes input, so one `HoverHandler` on the full-window item that holds
everything else hears every hover in the mask. Qt delivers hover to the topmost item under
the pointer and that item's ancestors, which decides both halves of the rule. Never derive
the reveal from handlers on the items that shape the mask: an item lying under the visible
surface may never hear about it. And never put the window-wide handler on an item laid over
everything: it becomes the topmost item itself, and no control under it is ever hovered.
Its `hovered` alone is not the answer, though: when the mask shrinks out from under a
still pointer, Hyprland sends no `leave` until the pointer moves. Gate it on the handler's
last `point.position` falling inside what the mask still holds.

**A modal surface's backdrop is a `MouseArea`, never a `TapHandler`.** Controls are built
on `TapHandler`, which takes only a passive grab on press, and a press nothing accepts
still reaches every `TapHandler` underneath — a tap on a control would also tap the
backdrop. A `MouseArea` only receives presses no item above it accepted, and a catcher
`MouseArea` filling the surface itself accepts all of those, so empty space inside the
surface never closes it either.

**Panels are `Item`s that a feature owns**, sized from their content via `implicitWidth`/
`implicitHeight`. They never position themselves in the window; the bar does that. A panel
owns its inner padding; the window owns where it sits.

**A layer surface takes keyboard focus only while something there wants keys.** Default to
`WlrKeyboardFocus.None`. While a form with no text field is open — the dashboard, for
`Escape` — use `OnDemand`: the keyboard comes over on the first click inside it. Use
`Exclusive` only for as long as a text field is open, driven by a property the panel
exposes. A surface left focusable steals the keyboard from the focused window on every
click; one left exclusive holds the keyboard hostage, so every such form needs an escape
that cannot be missed — `Escape`, a visible cancel, and a timeout on whatever it is waiting
for. *(Rewritten: the first version allowed only None and Exclusive.)*

Never hold `Exclusive` across something the user might do elsewhere. While it is held no
window can take focus, so a workspace switch leaves Hyprland remembering a window on the
old workspace, and the moment the surface lets go, Hyprland focuses that window and takes
the user back to it.

Once there are three panels, split each into a `Wrapper`/`Content` pair: `Wrapper` owns
geometry, visibility and animation and holds a `Loader`; `Content` is the UI and exists
only while open; state that must survive the unload is hoisted to a sibling. Before three,
this is ceremony.

## 7. Animation

Duration and easing come from `Animations`. A literal `duration: 200` is a bug.

Animate properties that describe the layout — padding, offsets, a `0..1` progress — and let
geometry derive from them. Never animate `scale` on anything containing text, and never
animate a window's size.

Anything whose geometry is driven by hover must present a **fixed-size hover area**; the
visual animates inside it. An element that both detects hover and resizes on hover
oscillates at its own edges. A `transform` carries the hit area with it, so an item that
owns a `HoverHandler` must stay put and the animation go on a child: a moving item sweeps
its own hover region across the pointer and fires on the way past.

Cross-fades hand over rather than overlap: when one element replaces another in the same
slot, stage the opacities so the first reaches 0 before the second leaves 0.

## 8. Compositor integration

Hyprland-side configuration belongs in `~/.config/hypr/hyprland.lua` (the Lua parser is
live on this machine; `hyprctl keyword` does not work — use `hyprctl eval` with `hl.*`).

Keep the division clean: **the compositor owns key bindings and window rules; the shell
observes and displays.** Volume keys run `wpctl`; the shell notices the resulting PipeWire
change and shows an OSD. Neither needs to know about the other, and the OSD then works for
every source of change — media keys, a terminal, a headset button.

The shell may grow an `IpcHandler` when the compositor genuinely needs to command it
(toggling a panel from a keybind). Prefer observation first; a shell that only listens
cannot get out of sync.

Compositor-side animation must be disabled for our surfaces
(`hl.layer_rule { match = { namespace = "^quickshell:dilico$" }, no_anim = true }`). Two
animators on one surface fight; the shell owns its own motion.

**One instance at a time.** Start it with `qs -c dilico -n -d`; `-n` refuses a second copy.
Two instances draw two identical surfaces on the same edge, fight over the same hover,
and only one can own the notification name. Hot reload is not guaranteed either: a file
replaced by rename rather than rewritten in place can be missed by the watcher. When a
saved change does not show, check `qs log -c dilico --log-times` for a reload after the save
before debugging the code.

## 9. Deferred by design

Not missing, not owed. Each of these is the right call for the code as it stands, and
each has a condition that makes it the wrong call. Build it when the condition fires, not
before.

| Deferred | Build it when |
|---|---|
| Splitting a panel host into a `Wrapper`/`Content` pair (§6) | A third panel exists. At one, the indirection costs more than it saves |
| `Variants { model: Quickshell.screens }`, delegate taking `required property ShellScreen modelData` | The bar should appear on a second monitor |
| User config as JSON via `FileView` + `JsonAdapter`, with a version number and migrations | Someone other than the author configures this. Constants in `config/` singletons are correct until then |
| `IpcHandler` for compositor-driven commands | A keybind must command the shell. Observation is preferred while it suffices (§8) |
| A committed lint and format check in CI | More than one person commits |

## 10. Why these rules

Provenance, so the rules can be argued with rather than obeyed blindly.

Quickshell's documentation mandates only that a config is a directory containing
`shell.qml`. It prescribes no internal layout, and every official example is flat. The
directory scheme above is convention, drawn from the configs that have survived contact
with real use: caelestia-dots/shell, end-4/dots-hyprland, DankMaterialShell,
noctalia-shell, and outfoxxed's own. All five converge on the same shape —
thin `shell.qml`, `modules/<feature>/`, `services/` of singletons, reusable widgets apart
from features, constants in singletons, no `qmldir`, `qs.` imports, an explicit layer-shell
namespace per surface.

Caelestia is the closest model here and the source of the `components/`-never-imports-
`modules/` rule, the `Wrapper`/`Content` idiom, and the one-masked-window-per-screen
architecture — which this config had already arrived at independently, which is some
evidence it is right.

Where they disagree, this blueprint simply picks: lowercase directories; masks over
multiple windows; observation over IPC. Those are choices, not findings.

Two cautions from the Quickshell project itself are worth repeating. The guide notes that
"most configs don't reflect current best practice", and the maintainer labels his own
config "DO NOT STEAL BLINDLY". Treat the five surveyed configs as evidence, never as
authority. Note also that the "official recommended structure" that circulates in search
results traces to third-party READMEs and AI-generated documentation sites, not to the
project.

The rules in §6 and §7 are not borrowed at all — they were paid for. Each one corresponds
to a specific failure in this codebase: a hover feedback loop from an element that resized
under its own pointer; text jitter from centring with fractional padding; a bounce from
renegotiating the layer surface size every frame; a panel stuck open because a stale
pointer position survived a missing `leave` event; a crash from a binding loop where a
`PwObjectTracker` was fed by a list that the tracking itself modified.

Later rewrites paid for six more, each now a rule in §6 or §8:

- **The taller band** (the first version's rule) blocked the top 48 px of the screen whenever the
  notch showed. Replaced by the notch plus a margin, with the travel covered by the hold.
- **Hover read from items under the surface** left the notch believing nobody was there
  while the pointer sat on it; it hid and returned on every small movement. Replaced by the
  one window-wide `HoverHandler`.
- **A `TapHandler` backdrop** closed the dashboard on every tap of a tile or mute button.
  Reproduced in an offscreen `qmltestrunner` case before the fix; replaced by `MouseArea`.
- **`Exclusive` focus on the dashboard** sent the user back to the original workspace when
  it closed after a workspace switch. Replaced by `OnDemand`.
- **The window-wide `HoverHandler` on an overlay item** fixed the flicker but took every
  hover for itself: no control showed a hand cursor or a highlight, and the dashboard's
  idle timeout ran while the pointer was on it. Found in an offscreen `qmltestrunner` case;
  moved to the full-window item that is everything's ancestor.
- **`hovered` trusted after the mask shrank** kept the clock down after a click outside
  closed the dashboard: the pointer had been inside the full-screen mask, and no `leave`
  came when the mask let go of it. Replaced by checking the last pointer position against
  the strip and the pill's margin.

Two more cost time without being code: a second instance stacked on the first, and a
reload the watcher missed, each of which made a correct fix look broken (§8).

A second look at caelestia and noctalia (legacy-v4) in October 2026 brought in four more,
borrowed rather than paid for: `Pressable`, after caelestia's `StateLayer`; `Watch` and the
watcher count, after its `Ref`; `utils/`, after its `Icons` and `Strings`; and a wheel that
steps per notch of travel, after its `CustomMouseArea` — which also fixed `Slider` moving
5% on every touchpad event and dropping on every sideways scroll. The same survey is why
`"transparent"` and timer intervals are not theme: both projects write them literally
throughout. And it is why sizes still stay out of `config/` although both keep full token
scales: theirs are themes other people configure, which is §9's condition, not this one's.

Reference:

- <https://quickshell.org/docs/v0.3.1/guide/> · <https://quickshell.org/docs/v0.3.0/guide/qml-language/> · <https://quickshell.org/docs/v0.3.1/guide/advanced/>
- <https://github.com/quickshell-mirror/quickshell/blob/master/src/core/scan.cpp> — synthesized `qmldir`
- <https://github.com/caelestia-dots/shell> · <https://github.com/end-4/dots-hyprland> · <https://github.com/AvengeMedia/DankMaterialShell> · <https://github.com/noctalia-dev/noctalia-shell/tree/legacy-v4> · <https://git.outfoxxed.me/outfoxxed/nixnew>
