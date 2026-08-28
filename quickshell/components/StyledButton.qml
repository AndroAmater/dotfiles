import QtQuick
import "../theme"

Rectangle {
    id: root

    property string text: ""
    property bool active: false
    property bool destructive: false
    property bool enabled: true
    signal clicked()

    implicitWidth: label.implicitWidth + 28
    implicitHeight: 46
    color: !enabled ? Theme.background
        : active ? Theme.accent
        : mouse.containsMouse ? Theme.subtle
        : Theme.background
    border.color: destructive ? Theme.urgent : active ? Theme.accent : Theme.subtle
    border.width: 1
    radius: Theme.radius
    opacity: enabled ? 1 : 0.45

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.active ? Theme.background : root.destructive ? Theme.urgent : Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.popupFontSize
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
