import QtQuick
import Quickshell
import Quickshell.Io
import "../components"

ModuleButton {
    id: root

    property int percent: 0
    property bool available: false

    visible: available
    implicitWidth: available ? contentWidth : 0
    property real contentWidth: icon !== "" ? 94 : 0
    icon: "\uf185"
    label: percent + "%"
    tooltipText: "Backlight: " + percent + "%"

    onWheelMoved: delta => {
        var amount = delta > 0 ? "1%+" : "1%-"
        Quickshell.execDetached(["brightnessctl", "-c", "backlight", "set", amount])
        refreshTimer.restart()
    }

    function parse(raw) {
        var line = String(raw || "").trim().split(/\n/)[0] || ""
        var fields = line.split(",")
        available = fields.length >= 4
        if (available) percent = Math.round(Number(fields[3].replace("%", "")) || 0)
    }

    Process {
        id: brightnessProcess
        command: ["brightnessctl", "-c", "backlight", "-m"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parse(text)
        }
        onExited: function(exitCode) { if (exitCode !== 0) root.available = false }
    }

    Timer {
        id: refreshTimer
        interval: 2000
        running: true
        repeat: true
        onTriggered: if (!brightnessProcess.running) brightnessProcess.running = true
    }
}
