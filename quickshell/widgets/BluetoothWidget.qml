import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../components"
import "../theme"

Item {
    id: root

    property var settingsPanel: null
    property alias menuVisible: popup.visible

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connectedDevices: Bluetooth.devices.values.filter(function(device) {
        return device.connected
    })

    // Unnamed devices (mostly BLE beacons with rotating random addresses) constantly
    // appear/disappear and make rows jump under the cursor, so only show named or known ones.
    // Order: connected, then paired, then by name.
    readonly property var visibleDevices: {
        if (!adapter) return []
        return adapter.devices.values.filter(function(device) {
            return device.connected || device.paired || device.deviceName !== ""
        }).sort(function(a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            if (a.paired !== b.paired) return a.paired ? -1 : 1
            return a.name.localeCompare(b.name)
        })
    }

    visible: adapter !== null
    implicitWidth: visible ? button.implicitWidth : 0
    implicitHeight: Theme.barHeight

    ModuleButton {
        id: button
        anchors.fill: parent
        icon: "\uf293"
        iconFontFamily: Theme.brandFontFamily
        iconSize: 26
        iconColor: root.adapter && root.adapter.enabled ? Theme.accent : Theme.inactive
        label: root.connectedDevices.length > 0 ? root.connectedDevices.length.toString() : ""
        tooltipText: !root.adapter ? "No Bluetooth adapter"
            : !root.adapter.enabled ? "Bluetooth disabled"
            : root.connectedDevices.length > 0
                ? root.connectedDevices.map(function(device) { return device.name }).join(", ")
                : "Bluetooth enabled"
        hoverFill: true
        onClicked: mouseButton => {
            if (mouseButton === Qt.LeftButton) popup.visible = !popup.visible
        }
    }

    ControlPopup {
        id: popup
        anchorItem: root.settingsPanel || root
        settingsPanel: root.settingsPanel
        onVisibleChanged: {
            if (root.adapter && root.adapter.enabled) root.adapter.discovering = visible
        }

        PopupHeader {
            title: "Bluetooth"
            subtitle: root.connectedDevices.length > 0
                ? root.connectedDevices.length + " connected"
                : "No connected devices"
            action: StyledButton {
                text: root.adapter && root.adapter.enabled ? "On" : "Off"
                active: root.adapter && root.adapter.enabled
                enabled: root.adapter !== null
                onClicked: root.adapter.enabled = !root.adapter.enabled
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.subtle
        }

        SectionTitle {
            text: root.adapter && root.adapter.discovering ? "DEVICES  SCANNING" : "DEVICES"
        }

        ListView {
            id: deviceList
            width: parent.width
            height: 430
            clip: true
            spacing: 2

            model: ScriptModel {
                values: root.visibleDevices
            }

            delegate: Item {
                id: deviceDelegate
                required property var modelData
                width: deviceList.width
                height: 76

                DeviceRow {
                    anchors.left: parent.left
                    anchors.right: forgetButton.visible ? forgetButton.left : parent.right
                    anchors.rightMargin: forgetButton.visible ? 4 : 0
                    icon: "\uf293"
                    iconFontFamily: Theme.brandFontFamily
                    title: deviceDelegate.modelData.name || deviceDelegate.modelData.address
                    detail: deviceDelegate.modelData.batteryAvailable
                        ? Math.round(deviceDelegate.modelData.battery * 100) + "% battery"
                        : deviceDelegate.modelData.paired ? "Paired" : "Available"
                    actionText: deviceDelegate.modelData.connected ? "Disconnect"
                        : deviceDelegate.modelData.pairing ? "Pairing"
                        : deviceDelegate.modelData.paired ? "Connect" : "Pair"
                    active: deviceDelegate.modelData.connected
                    busy: deviceDelegate.modelData.pairing
                    onClicked: {
                        if (deviceDelegate.modelData.connected) deviceDelegate.modelData.disconnect()
                        else if (deviceDelegate.modelData.paired) deviceDelegate.modelData.connect()
                        else deviceDelegate.modelData.pair()
                    }
                }

                StyledButton {
                    id: forgetButton
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: deviceDelegate.modelData.paired && !deviceDelegate.modelData.connected
                    width: visible ? 62 : 0
                    text: "Forget"
                    destructive: true
                    onClicked: deviceDelegate.modelData.forget()
                }
            }

            Text {
                anchors.centerIn: parent
                visible: deviceList.count === 0
                text: root.adapter && root.adapter.enabled ? "No devices found" : "Bluetooth is disabled"
                color: Theme.inactive
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popupFontSize
            }
        }
    }

    // Starting discovery can fail (e.g. "Resource Not Ready" while the adapter is still
    // powering on); keep retrying while the popup is open instead of giving up.
    Timer {
        interval: 3000
        repeat: true
        running: popup.visible && root.adapter !== null && root.adapter.enabled && !root.adapter.discovering
        onTriggered: root.adapter.discovering = true
    }

    Connections {
        target: root.adapter

        function onEnabledChanged() {
            if (root.adapter) root.adapter.discovering = root.adapter.enabled && popup.visible
        }
    }
}
