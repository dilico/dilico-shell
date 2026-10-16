pragma Singleton

import Quickshell
import Quickshell.Services.UPower

// power-profiles-daemon. Named for what it controls, since PowerProfiles and
// PowerProfile are both taken by the backend this file reads from.
Singleton {
    id: root

    // Profiles are named here rather than passed out as backend enums, so the
    // panel never has to import UPower to say which one it means.
    readonly property var profiles: PowerProfiles.hasPerformanceProfile
        ? ["saver", "balanced", "performance"]
        : ["saver", "balanced"]

    readonly property string profile: {
        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            return "saver";
        case PowerProfile.Performance:
            return "performance";
        }
        return "balanced";
    }

    function setProfile(profile: string): void {
        switch (profile) {
        case "saver":
            PowerProfiles.profile = PowerProfile.PowerSaver;
            return;
        case "performance":
            PowerProfiles.profile = PowerProfile.Performance;
            return;
        }
        PowerProfiles.profile = PowerProfile.Balanced;
    }
}
