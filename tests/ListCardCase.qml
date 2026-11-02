import QtQuick
import QtTest

// A test case for one of the dashboard's lists: finds a row by its item and
// reads what the stand-in service was asked last.
TestCase {
    id: root

    // The ListCard under test, made afresh by each test's init().
    property var card: null
    // The stand-in service it reads, recording requests in `calls`.
    property var service: null

    function row(item: var): var {
        return findChild(root.card, "list").itemAtIndex(root.card.items.indexOf(item));
    }

    function switchControl(): var {
        return findChild(root.card, "switch");
    }

    function lastCall(): var {
        return root.service.calls[root.service.calls.length - 1];
    }

    // The visible item under `parent` showing `text`, or null: a fact in a
    // row's details, say.
    function findChildByText(parent: var, text: string): var {
        if (parent.visible && parent.text === text)
            return parent;
        for (const child of parent.children) {
            const found = root.findChildByText(child, text);
            if (found)
                return found;
        }
        return null;
    }

    // Opening a row changes its height; the list moves the rows under it on
    // its next layout pass, so a click has to wait for that.
    function clickWhenLaidOut(item: var): void {
        waitForRendering(root.card);
        mouseClick(item);
    }

    when: windowShown
}
