import QtQuick
import Quickshell
import "../theme"

PopupWindow {
    id: root

    required property Item anchorItem
    property var settingsPanel: null
    property int popupHeight: layout.implicitHeight + Theme.popupPadding * 2
    default property alias contentData: content.data

    implicitWidth: Theme.popupWidth
    implicitHeight: popupHeight
    color: "transparent"
    grabFocus: true

    anchor {
        item: root.anchorItem
        edges: Edges.Top | Edges.Right
        gravity: Edges.Top | Edges.Left
        margins.top: -6
    }

    PopupCard {
        anchors.fill: parent

        Column {
            id: layout
            anchors.fill: parent
            anchors.margins: Theme.popupPadding
            spacing: Theme.popupSpacing

            Item {
                visible: root.settingsPanel !== null
                width: parent.width
                height: 46

                StyledButton {
                    text: "‹ Settings"
                    onClicked: {
                        root.visible = false
                        root.settingsPanel.open()
                    }
                }

                StyledButton {
                    anchors.right: parent.right
                    text: "Close"
                    onClicked: root.visible = false
                }
            }

            Column {
                id: content
                width: parent.width
                spacing: Theme.popupSpacing
            }
        }
    }
}
