pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string sessionName: "quickshell-btop"
    readonly property string btopCommand: "exec btop --config \"$HOME/.config/quickshell/btop/btop.conf\""
    readonly property int columns: 120
    readonly property int rows: 36
    property string snapshot: ""

    function ensureRunning() {
        if (!sessionCheck.running && !sessionStart.running) sessionCheck.running = true
    }

    function open() {
        Quickshell.execDetached([
            "kitty",
            "--class", "quickshell-btop",
            "--title", "System Monitor",
            "sh", "-lc", btopCommand
        ])
    }

    function capture() {
        if (!captureProcess.running) captureProcess.running = true
    }

    Process {
        id: sessionCheck
        command: ["tmux", "has-session", "-t", root.sessionName]
        onExited: function(exitCode) {
            if (exitCode !== 0 && !sessionStart.running) sessionStart.running = true
            else if (exitCode === 0) root.capture()
        }
    }

    Process {
        id: sessionStart
        command: [
            "tmux", "new-session", "-d",
            "-x", root.columns.toString(), "-y", root.rows.toString(),
            "-s", root.sessionName, root.btopCommand
        ]
        onExited: function(exitCode) {
            if (exitCode === 0) root.capture()
        }
    }

    Process {
        id: captureProcess
        command: ["tmux", "capture-pane", "-p", "-e", "-t", root.sessionName]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.snapshot = text.replace(/\s+$/, "")
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.capture()
    }
}
