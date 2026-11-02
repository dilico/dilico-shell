pragma Singleton

import Quickshell

// The brightness scale the slider, the keys and the pill share, against the
// hardware's own units. 0 is the dimmest it goes, 1 full, along a curve: the
// units to the power of 1/4. The eye sees a step at the dim end as far bigger
// than the same step at the bright end, and the curve evens them out, so a
// key press moves it by the same amount anywhere.
Singleton {
    id: root

    readonly property int exponent: 4
    // The units 0 stands for: dim, but never black, which would leave no way
    // to see the slider again.
    readonly property int floor: 2
    // What a key press moves it by: 5%.
    readonly property int steps: 20

    // Where the floor falls on the curve.
    function bottom(max: int): real {
        return Math.pow(root.floor / max, 1 / root.exponent);
    }

    function toLevel(units: int, max: int): real {
        const bottom = root.bottom(max);
        return Math.max(0, (Math.pow(units / max, 1 / root.exponent) - bottom) / (1 - bottom));
    }

    function toUnits(level: real, max: int): int {
        const bottom = root.bottom(max);
        return Math.round(max * Math.pow(bottom + level * (1 - bottom), root.exponent));
    }

    // The next multiple of 5% from `units` in `direction`, 1 or -1, so a level
    // the slider left between two goes to the one the key points to; `units`
    // again at either end.
    function step(units: int, max: int, direction: int): int {
        for (let i = 0; i <= root.steps; i++) {
            const next = root.toUnits((direction > 0 ? i : root.steps - i) / root.steps, max);
            if (direction > 0 ? next > units : next < units)
                return next;
        }
        return units;
    }
}
