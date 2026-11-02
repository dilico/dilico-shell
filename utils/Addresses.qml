pragma Singleton

import QtQuick
import Quickshell

// Each interface's IPv4 addresses, by name, in the order they came, kept from
// the lines `ip -o -4` prints: `address show` lists them, `monitor address`
// reports each one added, and each one deleted with "Deleted " in front. Each
// function answers from its arguments alone.
Singleton {
    id: root

    // The addresses after one line: a new map when it changes anything, so a
    // binding sees the change, or else the same one.
    function apply(addresses: var, line: string): var {
        const match = line.match(/^(Deleted )?\d+: (\S+)\s+inet ([\d.]+)[/ ]/);
        if (!match)
            return addresses;
        const [, deleted, name, address] = match;
        const known = addresses[name] ?? [];
        if (deleted ? !known.includes(address) : known.includes(address))
            return addresses;
        const next = Object.assign({}, addresses);
        next[name] = deleted ? known.filter(a => a !== address) : known.concat(address);
        return next;
    }

    // The first an interface was given, the one DHCP or a profile set, before
    // any it gained later, such as a link-local fallback; or "".
    function first(addresses: var, name: string): string {
        return addresses[name]?.[0] ?? "";
    }
}
