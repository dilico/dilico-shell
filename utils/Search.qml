pragma Singleton

import QtQuick
import Quickshell
import qs.utils

// How well a typed query matches an app, and the apps in order of it. Each
// function answers from its arguments alone.
Singleton {
    id: root

    // Higher is better, 0 is no match. The name counts most: its start, then
    // the start of one of its words, then anywhere in it. The other words —
    // a generic name, keywords, a comment — count by the start of a word, and
    // last of all the initials of the name's words, so "vsc" finds Visual
    // Studio Code. query is lower case.
    function score(query: string, name: string, others: var): int {
        const n = name.toLowerCase();
        const words = root.words(n);
        if (n.startsWith(query))
            return 100;
        if (words.some(w => w.startsWith(query)))
            return 80;
        if (n.includes(query))
            return 60;
        if (others.some(o => root.words(o.toLowerCase()).some(w => w.startsWith(query))))
            return 40;
        return words.map(w => w[0]).join("").startsWith(query) ? 10 : 0;
    }

    // With no query, every app by name. Otherwise the ones that match, best
    // first; among equal matches the most launched first, then by name. An
    // app is anything with a desktop entry's id, name, genericName, comment
    // and keywords; launches counts them by id.
    function rankApps(query: string, apps: var, launches: var): var {
        const q = query.trim().toLowerCase();
        if (q === "")
            return apps.slice().sort((a, b) => Order.byName(a.name, b.name));
        const launched = app => launches[app.id] ?? 0;
        return apps.map(app => ({
                    app,
                    score: root.score(q, app.name, [app.genericName, app.comment, ...app.keywords])
                })).filter(m => m.score > 0).sort((a, b) => b.score - a.score || launched(b.app) - launched(a.app) || Order.byName(a.app.name, b.app.name)).map(m => m.app);
    }

    // Split at spaces and punctuation. Not by letter class: Qt's JavaScript
    // has no \p{L}, and a-z alone would split "Éditeur".
    function words(text: string): var {
        return text.split(/[\s\-_.,:;!?()\[\]\/+&]+/).filter(w => w !== "");
    }
}
