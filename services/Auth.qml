pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Checks the user's password the way logging in does: PAM's "login" stack,
// the one hyprlock's own PAM file includes. One check at a time.
Singleton {
    id: root

    readonly property string user: Quickshell.env("USER") ?? ""
    readonly property bool busy: pam.active

    // Why the last check failed, in words, or "". When too many wrong tries
    // have locked the account for a while, it is PAM's own word on that,
    // which says for how long.
    property string failure: ""

    // The password, held only until PAM asks for it.
    property string pending: ""

    signal succeeded()

    function check(password: string): void {
        if (pam.active || password === "")
            return;
        root.pending = password;
        root.failure = "";
        pam.start();
    }

    function failureText(result: int): string {
        switch (result) {
        case PamResult.Failed:
            return "wrong password";
        case PamResult.MaxTries:
            return "too many tries";
        }
        return "could not check the password";
    }

    // The account checked is the one named on screen.
    PamContext {
        id: pam

        user: root.user

        onResponseRequiredChanged: {
            if (!pam.responseRequired)
                return;
            pam.respond(root.pending);
            root.pending = "";
        }

        // pam_faillock's "The account is locked due to 3 failed logins."
        onMessageChanged: {
            if (pam.message.includes("locked"))
                root.failure = pam.message.toLowerCase().replace(/\.$/, "");
        }

        onCompleted: result => {
            root.pending = "";
            if (result === PamResult.Success) {
                root.succeeded();
                return;
            }
            if (root.failure === "")
                root.failure = root.failureText(result);
        }

        onError: {
            root.pending = "";
            root.failure = root.failureText(PamResult.Error);
        }
    }
}
