pragma Singleton

import Quickshell
import Quickshell.Io

// The time, to the minute, kept right across sleep.
Singleton {
    id: root

    readonly property date date: clock.date

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    // A clock's next tick is timed on the monotonic clock, which stops during
    // sleep, so after waking it would still be waiting out the rest of the
    // minute it fell asleep in, showing that minute. Restarting it reads the
    // time afresh and times the next tick from now.
    //
    // logind announces waking on the system bus with PrepareForSleep(false);
    // gdbus prints each signal as a line, and waits out logind restarting.
    // Quickshell has no D-Bus listener of its own.
    Process {
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1"]
        running: true

        stdout: SplitParser {
            onRead: line => {
                if (!line.includes("PrepareForSleep (false"))
                    return;
                clock.enabled = false;
                clock.enabled = true;
            }
        }
    }
}
