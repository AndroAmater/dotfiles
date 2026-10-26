import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../theme"

ModuleButton {
    id: root

    property bool running: false
    property bool recording: false

    visible: running
    icon: ""
    iconColor: recording ? Theme.urgent : Theme.foreground
    label: recording ? "REC" : ""
    labelColor: Theme.urgent
    hoverFill: true
    tooltipText: recording
        ? "hyprwhspr: recording (Super+D to stop)"
        : "hyprwhspr: ready (Super+D to record)"

    onClicked: button => {
        if (button === Qt.LeftButton) {
            Quickshell.execDetached(["hyprwhspr", "record", "toggle"])
        } else if (button === Qt.RightButton) {
            Quickshell.execDetached(["systemctl", "--user", "restart", "hyprwhspr.service"])
        }
        refreshDelay.restart()
    }

    function parse(raw) {
        var lines = String(raw || "").trim().split(/\n/)
        running = lines[0] === "active"
        recording = running && (lines[1] || "").trim().toLowerCase() === "true"
    }

    Process {
        id: statusProcess
        command: ["sh", "-c",
            "systemctl --user is-active hyprwhspr.service; "
            + "cat \"${XDG_RUNTIME_DIR:-/tmp}/hyprwhspr/recording_status\" 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: if (!statusProcess.running) statusProcess.running = true
    }

    Timer {
        id: refreshDelay
        interval: 300
        onTriggered: if (!statusProcess.running) statusProcess.running = true
    }
}
