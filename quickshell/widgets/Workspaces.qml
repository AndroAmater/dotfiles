import QtQuick
import Quickshell.Hyprland
import "../theme"

Row {
    id: root

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            id: workspaceButton
            required property var modelData

            readonly property bool shown: modelData.id > 0
            implicitWidth: shown ? Theme.barHeight : 0
            implicitHeight: Theme.barHeight
            visible: shown
            color: modelData.urgent ? Theme.urgent
                : modelData.active ? Theme.accent
                : "transparent"
            radius: Theme.radius

            Text {
                id: label
                anchors.centerIn: parent
                text: workspaceButton.modelData.name || "\u2022"
                color: workspaceButton.modelData.urgent ? Theme.foreground
                    : workspaceButton.modelData.active ? Theme.background
                    : Theme.inactive
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: workspaceButton.modelData.activate()
            }
        }
    }
}
