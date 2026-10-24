import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../theme"

Item {
    id: root

    property var settingsPanel: null
    property alias menuVisible: popup.visible

    property var profiles: ["Quiet", "Balanced", "Performance"]
    property string profile: ""
    property string acProfile: ""
    property string batteryProfile: ""
    property string keyboardLevel: ""
    property int chargeLimit: 100
    property int panelOverdrive: -1

    implicitWidth: button.implicitWidth
    implicitHeight: Theme.barHeight

    function run(command) {
        Quickshell.execDetached(["asusctl"].concat(command))
        refreshTimer.restart()
    }

    function refresh() {
        if (!stateProcess.running) stateProcess.running = true
        if (!profileListProcess.running) profileListProcess.running = true
    }

    function parseState(raw) {
        var text = String(raw || "")
        var match = text.match(/Active profile:\s*(\S+)/)
        profile = match ? match[1] : ""
        match = text.match(/AC profile\s+(\S+)/)
        acProfile = match ? match[1] : ""
        match = text.match(/Battery profile\s+(\S+)/)
        batteryProfile = match ? match[1] : ""
        match = text.match(/keyboard led brightness:\s*(\S+)/i)
        var level = match ? match[1].toLowerCase() : ""
        keyboardLevel = level.indexOf("med") === 0 ? "med" : level
        match = text.match(/charge limit:\s*(\d+)%/)
        if (match) chargeLimit = Number(match[1])
        match = text.match(/panel_overdrive:\s*\n\s*current:\s*\[([^\]]*)\]/)
        panelOverdrive = match ? Number((match[1].match(/\((\d+)\)/) || [0, -1])[1]) : -1
    }

    function setProfile(name) {
        profile = name
        run(["profile", "set", name])
    }

    function setKeyboard(level) {
        keyboardLevel = level
        run(["leds", "set", level])
    }

    function setChargeLimit(value) {
        chargeLimit = Math.round(value)
        run(["battery", "limit", String(chargeLimit)])
    }

    function setPanelOverdrive(value) {
        panelOverdrive = value
        run(["armoury", "set", "panel_overdrive", String(value)])
    }

    ModuleButton {
        id: button
        anchors.fill: parent
        icon: "\uf863"
        tooltipText: root.profile !== "" ? "Profile: " + root.profile : "ASUS"
        hoverFill: true
        onClicked: mouseButton => {
            if (mouseButton === Qt.LeftButton) popup.visible = !popup.visible
        }
    }

    ControlPopup {
        id: popup
        anchorItem: root.settingsPanel || root
        settingsPanel: root.settingsPanel
        onVisibleChanged: if (visible) root.refresh()

        PopupHeader {
            title: "ASUS"
            subtitle: root.acProfile !== ""
                ? "AC: " + root.acProfile + "  Battery: " + root.batteryProfile
                : "asusctl controls"
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.subtle
        }

        SectionTitle { text: "PROFILE" }

        Row {
            id: profileRow
            width: parent.width
            spacing: 8

            Repeater {
                model: root.profiles
                delegate: StyledButton {
                    required property string modelData
                    width: (profileRow.width - profileRow.spacing * (root.profiles.length - 1)) / root.profiles.length
                    text: modelData
                    active: root.profile === modelData
                    onClicked: root.setProfile(modelData)
                }
            }
        }

        SectionTitle { text: "KEYBOARD BACKLIGHT" }

        Row {
            id: keyboardRow
            width: parent.width
            spacing: 8

            Repeater {
                model: [
                    { label: "Off", value: "off" },
                    { label: "Low", value: "low" },
                    { label: "Med", value: "med" },
                    { label: "High", value: "high" }
                ]
                delegate: StyledButton {
                    required property var modelData
                    width: (keyboardRow.width - keyboardRow.spacing * 3) / 4
                    text: modelData.label
                    active: root.keyboardLevel === modelData.value
                    onClicked: root.setKeyboard(modelData.value)
                }
            }
        }

        SectionTitle { text: "BATTERY CHARGE LIMIT" }

        Row {
            width: parent.width
            height: 40
            spacing: 10

            Text {
                width: 28
                text: "\uf240"
                color: Theme.foreground
                font.family: Theme.awesomeFontFamily
                font.pixelSize: Theme.fontSize
            }

            StyledSlider {
                id: chargeSlider
                width: parent.width - 108
                from: 20
                to: 100
                stepSize: 5
                value: root.chargeLimit
                onPressedChanged: if (!pressed) root.setChargeLimit(value)
            }

            Text {
                width: 60
                text: Math.round(chargeSlider.value) + "%"
                color: Theme.foreground
                horizontalAlignment: Text.AlignRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popupSmallFontSize
            }
        }

        StyledButton {
            width: parent.width
            text: "Charge to 100% once"
            enabled: root.chargeLimit < 100
            onClicked: root.run(["battery", "oneshot"])
        }

        SectionTitle {
            visible: root.panelOverdrive >= 0
            text: "PANEL OVERDRIVE"
        }

        Row {
            id: overdriveRow
            visible: root.panelOverdrive >= 0
            width: parent.width
            spacing: 8

            Repeater {
                model: [
                    { label: "Off", value: 0 },
                    { label: "On", value: 1 }
                ]
                delegate: StyledButton {
                    required property var modelData
                    width: (overdriveRow.width - overdriveRow.spacing) / 2
                    text: modelData.label
                    active: root.panelOverdrive === modelData.value
                    onClicked: root.setPanelOverdrive(modelData.value)
                }
            }
        }
    }

    Process {
        id: stateProcess
        command: ["sh", "-c", "asusctl profile get; asusctl leds get; asusctl battery info; asusctl armoury get panel_overdrive"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseState(text)
        }
    }

    Process {
        id: profileListProcess
        command: ["asusctl", "profile", "list"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var names = String(text || "").trim().split(/\n/).filter(function(line) {
                    return /^\w+$/.test(line.trim())
                })
                if (names.length > 0) root.profiles = names.map(function(line) { return line.trim() })
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 600
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
