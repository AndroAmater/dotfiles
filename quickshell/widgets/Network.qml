import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../components"
import "../theme"

Item {
    id: root

    readonly property var wifiDevices: Networking.devices.values.filter(function(device) {
        return device.type === DeviceType.Wifi
    })
    readonly property var wiredDevices: Networking.devices.values.filter(function(device) {
        return device.type === DeviceType.Wired
    })
    readonly property var wifiDevice: wifiDevices.length > 0 ? wifiDevices[0] : null
    readonly property var activeDevice: {
        var connectedWifi = wifiDevices.find(function(device) { return device.connected })
        var connectedWired = wiredDevices.find(function(device) { return device.connected })
        return connectedWifi || connectedWired || null
    }
    readonly property var activeNetwork: {
        if (!activeDevice) return null
        return activeDevice.networks.values.find(function(network) { return network.connected }) || null
    }
    property var passwordNetwork: null
    property string ethernetAddress: ""
    property string gateway: ""

    implicitWidth: button.implicitWidth
    implicitHeight: Theme.barHeight

    function wifiIcon(strength) {
        return "\uf1eb"
    }

    function connectNetwork(network) {
        if (network.connected) {
            network.disconnect()
        } else if (network.known || network.security === WifiSecurityType.Open) {
            network.connect()
        } else if (supportsPsk(network)) {
            passwordNetwork = network
            passwordField.text = ""
            passwordField.forceActiveFocus()
        } else {
            Quickshell.execDetached(["nm-connection-editor"])
            popup.visible = false
        }
    }

    function supportsPsk(network) {
        return network.security === WifiSecurityType.WpaPsk
            || network.security === WifiSecurityType.Wpa2Psk
            || network.security === WifiSecurityType.Sae
    }

    function parseAddress(raw) {
        ethernetAddress = ""
        try {
            var devices = JSON.parse(String(raw || "[]"))
            if (devices.length === 0) return
            var address = devices[0].addr_info.find(function(entry) { return entry.family === "inet" })
            if (address) ethernetAddress = address.local + "/" + address.prefixlen
        } catch (error) {
            ethernetAddress = ""
        }
    }

    function parseRoutes(raw) {
        gateway = ""
        try {
            var routes = JSON.parse(String(raw || "[]"))
            if (!activeDevice) return
            var route = routes.find(function(entry) { return entry.dev === activeDevice.name })
            if (route && route.gateway) gateway = route.gateway
        } catch (error) {
            gateway = ""
        }
    }

    ModuleButton {
        id: button
        anchors.fill: parent
        icon: {
            return root.wifiIcon(root.activeNetwork ? root.activeNetwork.signalStrength : 0)
        }
        iconColor: root.activeDevice ? Theme.network : Theme.urgent
        label: root.activeDevice && root.activeDevice.type === DeviceType.Wired
            ? root.ethernetAddress || root.activeDevice.name
            : root.activeNetwork ? root.activeNetwork.name : "down"
        tooltipText: root.activeDevice
            ? root.activeDevice.name + (root.gateway ? " via " + root.gateway : "")
            : "Network disconnected"
        hoverFill: true
        onClicked: mouseButton => {
            if (mouseButton === Qt.LeftButton) popup.visible = !popup.visible
        }
    }

    ControlPopup {
        id: popup
        anchorItem: root
        onVisibleChanged: {
            if (root.wifiDevice) root.wifiDevice.scannerEnabled = visible
            if (!visible) root.passwordNetwork = null
        }

        PopupHeader {
            title: "Network"
            subtitle: root.activeNetwork ? "Connected to " + root.activeNetwork.name : "Not connected"
            action: StyledButton {
                text: Networking.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"
                active: Networking.wifiEnabled
                enabled: Networking.wifiHardwareEnabled
                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.subtle
        }

        Item {
            visible: root.passwordNetwork !== null
            width: parent.width
            height: visible ? 100 : 0

            Column {
                anchors.fill: parent
                spacing: 8

                Text {
                    text: "Password for " + (root.passwordNetwork ? root.passwordNetwork.name : "")
                    color: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popupFontSize
                }

                Row {
                    width: parent.width
                    spacing: 8

                    StyledTextField {
                        id: passwordField
                        width: parent.width - connectButton.width - parent.spacing
                        echoMode: TextInput.Password
                        placeholderText: "Network password"
                        onAccepted: connectButton.clicked()
                    }

                    StyledButton {
                        id: connectButton
                        text: "Connect"
                        active: true
                        enabled: passwordField.text.length >= 8
                        onClicked: {
                            if (!root.passwordNetwork) return
                            root.passwordNetwork.connectWithPsk(passwordField.text)
                            root.passwordNetwork = null
                        }
                    }
                }
            }
        }

        SectionTitle {
            text: root.wifiDevice && root.wifiDevice.scannerEnabled ? "WIRELESS NETWORKS  SCANNING" : "WIRELESS NETWORKS"
        }

        ListView {
            id: networkList
            width: parent.width
            height: root.passwordNetwork ? 330 : 420
            clip: true
            spacing: 2

            model: root.wifiDevice ? root.wifiDevice.networks : null

            delegate: DeviceRow {
                id: networkRow
                required property var modelData
                width: networkList.width
                icon: root.wifiIcon(modelData.signalStrength)
                title: modelData.name
                detail: Math.round(modelData.signalStrength * 100) + "%"
                    + (modelData.known ? "  saved" : "")
                actionText: modelData.connected ? "Disconnect"
                    : modelData.known || modelData.security === WifiSecurityType.Open || root.supportsPsk(modelData)
                        ? "Connect" : "Configure"
                active: modelData.connected
                busy: modelData.stateChanging
                onClicked: root.connectNetwork(modelData)

                Connections {
                    target: networkRow.modelData
                    function onConnectionFailed(reason) {
                        if (reason === ConnectionFailReason.NoSecrets) {
                            root.passwordNetwork = networkRow.modelData
                            passwordField.text = ""
                            passwordField.forceActiveFocus()
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: networkList.count === 0
                text: !Networking.wifiEnabled ? "Wi-Fi is disabled"
                    : root.wifiDevice ? "No networks found" : "No Wi-Fi adapter"
                color: Theme.inactive
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popupFontSize
            }
        }
    }

    Process {
        id: addressProcess
        command: root.activeDevice
            ? ["ip", "-j", "address", "show", "dev", root.activeDevice.name]
            : ["true"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseAddress(text)
        }
    }

    Process {
        id: routeProcess
        command: ["ip", "-j", "route", "show", "default"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseRoutes(text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!addressProcess.running) addressProcess.running = true
            if (!routeProcess.running) routeProcess.running = true
        }
    }
}
