import QtQuick
import QtTest
import qs.modules.island.components

Item {
    width: 400
    height: 200

    Component {
        id: stripComponent

        WorkspaceStrip {}
    }

    TestCase {
        name: "WorkspaceStrip"
        when: windowShown

        function chip(strip: Item, i: int): Item {
            return findChild(strip, "chips").itemAt(i);
        }

        function test_widthFollowsTheCountNotTheHighlight() {
            const strip = createTemporaryObject(stripComponent, parent, {
                workspaces: [
                    { number: 1, current: false },
                    { number: 3, current: true }
                ]
            });
            waitForRendering(strip);
            const two = strip.implicitWidth;
            strip.workspaces = [
                { number: 1, current: true },
                { number: 3, current: false }
            ];
            waitForRendering(strip);
            compare(strip.implicitWidth, two, "moving the highlight keeps the width");
            strip.workspaces = [
                { number: 1, current: false },
                { number: 3, current: false },
                { number: 10, current: true }
            ];
            waitForRendering(strip);
            verify(strip.implicitWidth > two, "a third workspace widens it");
            compare(chip(strip, 2).width, chip(strip, 0).width, "10 takes no more room than 1");
        }

        function test_theCurrentOneIsInverted() {
            const strip = createTemporaryObject(stripComponent, parent, {
                workspaces: [
                    { number: 2, current: false },
                    { number: 6, current: true }
                ]
            });
            waitForRendering(strip);
            verify(chip(strip, 1).active, "the current one is inverted");
            verify(!chip(strip, 0).active, "the others are not");
        }

        // The pill takes its width from the strip before it comes down, so
        // the strip has to lay itself out while it is still hidden.
        function test_measuresWhileHidden() {
            const strip = createTemporaryObject(stripComponent, parent, {
                visible: false,
                workspaces: [{ number: 1, current: true }]
            });
            waitForRendering(parent);
            const one = strip.implicitWidth;
            strip.workspaces = [
                { number: 1, current: false },
                { number: 2, current: true }
            ];
            waitForRendering(parent);
            verify(strip.implicitWidth > one, "it grew while hidden");
        }
    }
}
