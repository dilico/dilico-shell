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

---

## 1. Where does this go?

Ask, in order, and stop at the first yes:

1. **Does it talk to the outside world** — PipeWire, D-Bus, the filesystem, a subprocess,
   the compositor? → `services/`, as a singleton.
2. **Is it a constant** — a colour, a duration, a glyph, a font size? → `config/`, as a
   singleton.
3. **Could another feature reasonably use it, with no change?** → `components/`.
4. **Does it belong to exactly one feature?** → `modules/<feature>/`.
5. **Is it the window itself, or a pragma?** → `shell.qml`.

If two answers feel right, you are holding two things. Split it.

## 2. Directory contracts

```
shell.qml                   windows, pragmas, wiring — nothing else
components/                 feature-agnostic visual primitives
modules/<feature>/          one directory per surface
modules/<feature>/panels/   panels that surface hosts
services/                   singletons that own external state
config/                     singletons that own constants
docs/                       this file
```

### `shell.qml`

Contains instance pragmas **[engine]**, the `PanelWindow`(s), their masks and exclusive
zones, and the instantiation of top-level feature modules. Nothing that could be tested or
reasoned about on its own belongs here.

It grows by roughly one block per surface. If it is growing for any other reason, the
thing that is growing belongs in a module.

### `components/`

Generic, reusable, visual. `Icon`, `Slider`, and anything else another feature could adopt
unchanged.

**A file in `components/` must never import `qs.modules`.** This is the load-bearing rule
of the whole layout — it is what keeps "reusable" honest. A component that needs to know
about volume is not a component; it is a feature widget, and it belongs in
`modules/<feature>/`.

Components take their behaviour through properties and report through signals. They never
read a service and never decide policy. `Slider` emits `moved(value)`; it does not know
that something will set a PipeWire volume.

### `modules/<feature>/`

One directory per feature — `bar/`, `volume/`, `brightness/`. A feature owns its layout,
its panel, and any widget too specific to promote. Subdivide with
`modules/<feature>/components/` once a feature grows its own private widgets.

A feature may import `qs.components`, `qs.services`, `qs.config`, and its own directory. It
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

The test: if the panel's bindings are longer than `Audio.volume`, logic has leaked.

### `config/`

Singletons of constants only, one per concern: `Colors`, `Typography`, `Animations`,
`Glyphs`. No logic, no state, no IO.

Every colour in the codebase comes from `Colors`. Every duration and easing from
`Animations`. Every font family and size from `Typography`. Every glyph from `Glyphs`. A
literal `"#98C379"`, `200`, or `""` anywhere else is a bug — one-off values are how
a theme stops being changeable in one place.

`Glyphs` entries are declared `String.fromCodePoint(0x…)`, never pasted characters or
surrogate pairs. Verify a codepoint by rendering it from the installed font before adding
it; the Nerd Fonts cheat sheets are wrong often enough to matter.

Sizes, radii and spacings are **not** config. A corner radius or a panel width is a
property of the thing that draws it, and belongs in that file. It graduates to `config/`
the moment a second file needs the same value — at which point it is shared design, not a
local choice. Do not build a token system in advance of that.

## 3. Every file

Start every file with:

```qml
pragma ComponentBehavior: Bound   // if it contains a delegate or Component

import QtQuick
import Quickshell...              // Quickshell modules next
import qs.components              // then ours, alphabetically
import qs.config
import qs.services
```

Alphabetical rather than layered, because it is mechanical: there is never a question of
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
qmllint -I /run/user/1000/quickshell/vfs/<shell-id> modules/*.qml components/*.qml services/*.qml config/*.qml shell.qml
```

A `// qmllint disable <rule>` is allowed only for a verified false positive, on the
narrowest possible scope, with the reason in a comment.

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
must run at startup — one registering an IPC handler or a global shortcut — needs an
explicit reference from a live object to force it.

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
(`quickshell:bar`), so compositor rules can target one surface rather than everything.

**The window never resizes in response to interaction.** Its height is a constant ceiling
large enough for the tallest panel; the extra is transparent and masked out. Resizing a
layer surface hands the compositor a frame to animate or stretch, and the result is
visible jitter no amount of QML smoothing will fix.

**Input comes from the `mask` region**, bound to the geometry of what is actually visible.
Where an animated element drives the mask, the region must be a superset of both the
resting and expanded shapes, so it can never shrink out from under the pointer mid-animation.

**Panels are `Item`s that a feature owns**, sized from their content via `implicitWidth`/
`implicitHeight`. They never position themselves in the window; the bar does that.

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
oscillates at its own edges.

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
(`hl.layer_rule { match = { namespace = "^quickshell:bar$" }, no_anim = true }`). Two
animators on one surface fight; the shell owns its own motion.

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

Reference:

- <https://quickshell.org/docs/v0.3.1/guide/> · <https://quickshell.org/docs/v0.3.0/guide/qml-language/> · <https://quickshell.org/docs/v0.3.1/guide/advanced/>
- <https://github.com/quickshell-mirror/quickshell/blob/master/src/core/scan.cpp> — synthesized `qmldir`
- <https://github.com/caelestia-dots/shell> · <https://github.com/end-4/dots-hyprland> · <https://github.com/AvengeMedia/DankMaterialShell> · <https://github.com/noctalia-dev/noctalia-shell/tree/legacy-v4> · <https://git.outfoxxed.me/outfoxxed/nixnew>
