pragma Singleton

import QtQuick
import Quickshell

// Hyprland's monitor rules as the displays pane writes them: an hl.monitor
// call per monitor, sent live through hyprctl eval and kept in monitors.lua,
// one per line, in the one form `call` writes and `parse` reads back
// (conventions §8). A rule is { output, mode, x, y, scale, transform }, with
// scale as text, the way Hyprland's config takes it, and `port` alongside
// when the monitor is plugged in. Each function answers from its arguments
// alone.
Singleton {
    id: root

    // A Lua string literal.
    function quote(text: string): string {
        return `"${text.replace(/\\/g, "\\\\").replace(/"/g, "\\\"")}"`;
    }

    // The inverse of quote, for what is inside the quotes.
    function unquote(text: string): string {
        return text.replace(/\\(.)/g, "$1");
    }

    // A monitor's rule, from the monitor as services/Displays has it. By
    // description, which stays with the monitor whichever port it is in, or
    // by port when it has none.
    function rule(m: var): var {
        return {
            output: m.description ? `desc:${m.description}` : m.name,
            port: m.name,
            mode: root.modeText(m.width, m.height, m.refresh),
            x: m.x,
            y: m.y,
            scale: String(m.scale),
            transform: m.transform
        };
    }

    function call(rule: var): string {
        return `hl.monitor({ output = ${root.quote(rule.output)}, mode = ${root.quote(rule.mode)}, position = "${rule.x}x${rule.y}", scale = ${root.quote(rule.scale)}, transform = ${rule.transform} })`;
    }

    // The whole of monitors.lua.
    function file(rules: var): string {
        const header = ["-- Monitors as dilico's displays pane left them; hyprland.lua runs this file.", "-- The pane rewrites it whole and drops any line not in its own form, so set", "-- anything else about a monitor in hyprland.lua."];
        return header.concat(rules.map(root.call)).join("\n") + "\n";
    }

    // The rules in a file `file` wrote; any other line is left out.
    function parse(text: string): var {
        const literal = String.raw`"((?:[^"\\]|\\.)*)"`;
        const form = new RegExp(String.raw`^hl\.monitor\(\{ output = ${literal}, mode = ${literal}, position = "(-?\d+)x(-?\d+)", scale = "([^"]*)", transform = (\d) \}\)$`);
        const rules = [];
        for (const line of text.split("\n")) {
            const m = line.match(form);
            if (m === null)
                continue;
            rules.push({
                output: root.unquote(m[1]),
                mode: root.unquote(m[2]),
                x: Number(m[3]),
                y: Number(m[4]),
                scale: m[5],
                transform: Number(m[6])
            });
        }
        return rules;
    }

    // The saved rules with the plugged-in monitors' rules in place of their
    // old ones: a saved rule goes when it names one of them, by description
    // or by port. The rest are monitors not plugged in now, and stay.
    function merge(saved: var, current: var): var {
        return saved.filter(s => !current.some(c => s.output === c.output || s.output === c.port)).concat(current);
    }

    // A mode as hyprctl lists it, "1920x1200@60.00Hz", as { width, height,
    // refresh }, or null.
    function mode(text: string): var {
        const m = text.match(/^(\d+)x(\d+)@([\d.]+)Hz$/);
        return m === null ? null : {
            width: Number(m[1]),
            height: Number(m[2]),
            refresh: Number(m[3])
        };
    }

    // Whether a mode is the one a monitor is in: hyprctl gives the monitor's
    // rate as measured, 60.003, and its modes' rounded, "60.00Hz".
    function sameMode(mode: var, m: var): bool {
        return mode.width === m.width && mode.height === m.height && Math.abs(mode.refresh - m.refresh) < 0.01;
    }

    // A mode as a rule names it.
    function modeText(width: int, height: int, refresh: real): string {
        return `${width}x${height}@${refresh.toFixed(2)}`;
    }
}
