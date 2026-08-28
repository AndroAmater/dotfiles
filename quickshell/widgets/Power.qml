import QtQuick
import Quickshell
import "../components"
import "../theme"

Item {
    id: root

    implicitWidth: button.implicitWidth
    implicitHeight: Theme.barHeight

    function run(command) {
        popup.visible = false
        Quickshell.execDetached(command)
    }

    ModuleButton {
        id: button
        anchors.fill: parent
        icon: "\uf011"
        hoverFill: true
        onClicked: mouseButton => {
            if (mouseButton === Qt.LeftButton) popup.visible = !popup.visible
        }
    }

    ControlPopup {
        id: popup
        anchorItem: root
        grabFocus: true

        PopupHeader {
            title: "Power"
            subtitle: "Session and system controls"
        }

        Column {
            width: parent.width
            spacing: 10

            StyledButton {
                width: parent.width
                text: "Lock screen"
                onClicked: root.run(["swaylock", "-f"])
            }

            StyledButton {
                width: parent.width
                text: "Log out"
                onClicked: root.run(["hyprctl", "dispatch", "exit"])
            }

            StyledButton {
                width: parent.width
                text: "Restart"
                destructive: true
                onClicked: root.run(["systemctl", "reboot"])
            }

            StyledButton {
                width: parent.width
                text: "Shut down"
                destructive: true
                onClicked: root.run(["systemctl", "poweroff"])
            }
        }
    }
}
