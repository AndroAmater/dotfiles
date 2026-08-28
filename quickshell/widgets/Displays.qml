import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../theme"

Item {
    id: root

    property var monitors: []
    property var selectedMonitor: monitors.length > 0 ? monitors[0] : null
    property bool ddcAvailable: false
    property int brightness: 0
    property int brightnessMax: 100

    implicitWidth: Theme.barHeight
    implicitHeight: Theme.barHeight

    function apply(scale, transform) {
        if (!selectedMonitor) return
        var monitor = selectedMonitor
        var mode = monitor.width + "x" + monitor.height + "@"
            + Number(monitor.refreshRate).toFixed(3)
        var position = monitor.x + "x" + monitor.y
        Quickshell.execDetached([
            Quickshell.env("HOME") + "/.config/hypr/set-monitor",
            monitor.name,
            mode,
            position,
            String(scale),
            String(transform)
        ])
        selectedMonitor = Object.assign({}, monitor, { scale: scale, transform: transform })
        monitors = monitors.map(function(entry) {
            return entry.name === monitor.name ? selectedMonitor : entry
        })
        refreshTimer.restart()
    }

    function parseMonitors(raw) {
        try {
            var parsed = JSON.parse(String(raw || "[]"))
            monitors = parsed
            if (!selectedMonitor || !parsed.some(function(monitor) { return monitor.name === selectedMonitor.name }))
                selectedMonitor = parsed.length > 0 ? parsed[0] : null
            else
                selectedMonitor = parsed.find(function(monitor) { return monitor.name === selectedMonitor.name })
        } catch (error) {
            monitors = []
            selectedMonitor = null
        }
    }

    function parseBrightness(raw) {
        var match = String(raw || "").match(/VCP 10 C (\d+) (\d+)/)
        ddcAvailable = match !== null
        if (match) {
            brightness = Number(match[1])
            brightnessMax = Number(match[2])
        }
    }

    function setBrightness(value) {
        brightness = Math.round(value)
        Quickshell.execDetached(["ddcutil", "setvcp", "10", String(brightness)])
    }

    ModuleButton {
        id: button
        anchors.fill: parent
        icon: "\uf108"
        label: ""
        tooltipText: root.monitors.length + (root.monitors.length === 1 ? " display" : " displays")
        hoverFill: true
        onClicked: mouseButton => {
            if (mouseButton === Qt.LeftButton) {
                monitorProcess.running = true
                if (root.monitors.length === 1) brightnessProcess.running = true
                popup.visible = !popup.visible
            }
        }
    }

    ControlPopup {
        id: popup
        anchorItem: root
        PopupHeader {
            title: "Displays"
            subtitle: root.selectedMonitor ? root.selectedMonitor.description : "No active display"
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.subtle
        }

        SectionTitle { text: "ACTIVE DISPLAY" }

        Row {
            width: parent.width
            spacing: 8

            Repeater {
                model: root.monitors
                delegate: StyledButton {
                    required property var modelData
                    text: modelData.name
                    active: root.selectedMonitor && root.selectedMonitor.name === modelData.name
                    onClicked: root.selectedMonitor = modelData
                }
            }
        }

        Text {
            text: root.selectedMonitor
                ? root.selectedMonitor.width + "x" + root.selectedMonitor.height + " @ "
                    + Number(root.selectedMonitor.refreshRate).toFixed(2) + " Hz"
                : "No monitor data"
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popupFontSize
        }

        SectionTitle { text: "SCALE" }

        Row {
            width: parent.width
            spacing: 8

            Repeater {
                model: [1, 1.25, 1.5, 2]
                delegate: StyledButton {
                    required property real modelData
                    text: modelData + "x"
                    active: root.selectedMonitor && Math.abs(root.selectedMonitor.scale - modelData) < 0.01
                    enabled: root.selectedMonitor !== null
                    onClicked: root.apply(modelData, root.selectedMonitor.transform)
                }
            }
        }

        SectionTitle {
            visible: root.ddcAvailable && root.monitors.length === 1
            text: "MONITOR BRIGHTNESS"
        }

        Row {
            visible: root.ddcAvailable && root.monitors.length === 1
            width: parent.width
            height: visible ? 40 : 0
            spacing: 10

            Text {
                width: 28
                text: "\uf185"
                color: Theme.foreground
                font.family: Theme.awesomeFontFamily
                font.pixelSize: Theme.fontSize
            }

            StyledSlider {
                width: parent.width - 88
                from: 0
                to: root.brightnessMax
                stepSize: 1
                value: root.brightness
                onPressedChanged: if (!pressed) root.setBrightness(value)
            }

            Text {
                width: 40
                text: root.brightness + "%"
                color: Theme.foreground
                horizontalAlignment: Text.AlignRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popupSmallFontSize
            }
        }

        SectionTitle { text: "ROTATION" }

        Row {
            width: parent.width
            spacing: 8

            Repeater {
                model: [
                    { label: "0", value: 0 },
                    { label: "90", value: 1 },
                    { label: "180", value: 2 },
                    { label: "270", value: 3 }
                ]
                delegate: StyledButton {
                    required property var modelData
                    text: modelData.label + " deg"
                    active: root.selectedMonitor && root.selectedMonitor.transform === modelData.value
                    enabled: root.selectedMonitor !== null
                    onClicked: root.apply(root.selectedMonitor.scale, modelData.value)
                }
            }
        }

        Text {
            text: root.selectedMonitor
                ? "Changes are applied immediately and saved to monitors.conf."
                : ""
            color: Theme.inactive
            wrapMode: Text.WordWrap
            width: parent.width
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popupSmallFontSize
        }
    }

    Process {
        id: monitorProcess
        command: ["hyprctl", "-j", "monitors"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseMonitors(text)
        }
    }

    Process {
        id: brightnessProcess
        command: ["ddcutil", "getvcp", "10", "--brief"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseBrightness(text)
        }
        onExited: function(exitCode) { if (exitCode !== 0) root.ddcAvailable = false }
    }

    Timer {
        id: refreshTimer
        interval: 1000
        repeat: false
        onTriggered: if (!monitorProcess.running) monitorProcess.running = true
    }
}
