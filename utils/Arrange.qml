pragma Singleton

import QtQuick
import Quickshell

// Where monitors sit beside each other, in Hyprland's layout pixels: a mode
// divided by its scale, and turned with the monitor. A rect is
// { name, x, y, width, height } in those pixels; a monitor is shaped as
// services/Displays has them. Each function answers from its arguments alone.
Singleton {
    id: root

    // A monitor's size on the layout. Transforms 1, 3, 5 and 7 stand it on
    // its side.
    function size(width: int, height: int, scale: real, transform: int): var {
        const turned = transform % 2 === 1;
        return {
            width: Math.round((turned ? height : width) / scale),
            height: Math.round((turned ? width : height) / scale)
        };
    }

    // Each monitor's rect, in the same order.
    function rects(monitors: var): var {
        return monitors.map(m => Object.assign({
                name: m.name,
                x: m.x,
                y: m.y
            }, root.size(m.width, m.height, m.scale, m.transform)));
    }

    // The monitors moved to where the rects say.
    function placed(monitors: var, rects: var): var {
        return monitors.map(m => {
            const r = rects.find(r => r.name === m.name);
            return Object.assign({}, m, {
                x: r.x,
                y: r.y
            });
        });
    }

    // The rects with `name` moved to touch another along a side, as near to
    // (x, y) as that allows without covering any, then all shifted so the
    // layout starts at 0, 0. Alone, it sits at 0, 0. With nowhere to go, it
    // stays where it was.
    function place(rects: var, name: string, x: real, y: real): var {
        const moving = rects.find(r => r.name === name);
        const others = rects.filter(r => r.name !== name);
        let best = {
            x: moving.x,
            y: moving.y
        };
        let nearest = Infinity;
        for (const other of others) {
            for (const spot of root.spots(moving, other, x, y)) {
                const placed = Object.assign({}, moving, spot);
                if (others.some(r => root.overlap(placed, r)))
                    continue;
                const distance = Math.hypot(spot.x - x, spot.y - y);
                if (distance < nearest) {
                    best = spot;
                    nearest = distance;
                }
            }
        }
        return root.normalize(rects.map(r => r.name === name ? Object.assign({}, r, best) : r));
    }

    // After `name` changed size: every other rect placed again near where it
    // was, so none covers it or is left standing apart from it.
    function settle(rects: var, name: string): var {
        let out = rects;
        for (const rect of rects) {
            if (rect.name === name)
                continue;
            const now = out.find(r => r.name === rect.name);
            out = root.place(out, rect.name, now.x, now.y);
        }
        return out;
    }

    // The four places `m` can touch `other`: left of it, right of it, above it
    // and below it, each slid along that side to near (x, y).
    function spots(m: var, other: var, x: real, y: real): var {
        const alongY = root.slide(y, m.height, other.y, other.height);
        const alongX = root.slide(x, m.width, other.x, other.width);
        return [
            {
                x: other.x - m.width,
                y: alongY
            },
            {
                x: other.x + other.width,
                y: alongY
            },
            {
                x: alongX,
                y: other.y - m.height
            },
            {
                x: alongX,
                y: other.y + other.height
            }
        ];
    }

    // Where something `length` long starts beside a side that starts at
    // `start` and is `side` long, near `want`. It lines up with the side's
    // ends or middle when within a tenth of its own length of them, and
    // always shares at least a tenth of the shorter of the two.
    function slide(want: real, length: int, start: int, side: int): int {
        const lined = [start, start + side - length, start + (side - length) / 2];
        const nearest = lined.reduce((a, b) => Math.abs(b - want) < Math.abs(a - want) ? b : a);
        const at = Math.abs(nearest - want) <= length / 10 ? nearest : want;
        const share = Math.max(1, Math.round(Math.min(length, side) / 10));
        return Math.round(Math.min(Math.max(at, start - length + share), start + side - share));
    }

    // Whether two rects cover any of the same area; touching is not.
    function overlap(a: var, b: var): bool {
        return a.x < b.x + b.width && b.x < a.x + a.width && a.y < b.y + b.height && b.y < a.y + a.height;
    }

    // The rects shifted so the leftmost starts at x 0 and the topmost at y 0.
    function normalize(rects: var): var {
        const left = Math.min(...rects.map(r => r.x));
        const top = Math.min(...rects.map(r => r.y));
        return rects.map(r => Object.assign({}, r, {
                x: r.x - left,
                y: r.y - top
            }));
    }

    // How to draw the rects in a box `width` by `height`, `margin` in from
    // its edges: a pixel on the layout is `scale` in the box, and the layout's
    // 0, 0 is at (x, y), so the whole layout is centred.
    function fit(rects: var, width: real, height: real, margin: real): var {
        if (rects.length === 0)
            return {
                scale: 0,
                x: 0,
                y: 0
            };
        const left = Math.min(...rects.map(r => r.x));
        const top = Math.min(...rects.map(r => r.y));
        const right = Math.max(...rects.map(r => r.x + r.width));
        const bottom = Math.max(...rects.map(r => r.y + r.height));
        const scale = Math.max(0, Math.min((width - 2 * margin) / (right - left), (height - 2 * margin) / (bottom - top)));
        return {
            scale,
            x: Math.round((width - (right - left) * scale) / 2 - left * scale),
            y: Math.round((height - (bottom - top) * scale) / 2 - top * scale)
        };
    }
}
