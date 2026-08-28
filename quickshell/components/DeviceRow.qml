import QtQuick
import "../theme"

Rectangle {
    id: root

    property string icon: ""
    property string iconFontFamily: Theme.iconFontFamily
    property string title: ""
    property string detail: ""
    property string actionText: ""
    property bool active: false
    property bool busy: false
    property bool actionEnabled: true
    signal clicked()

    width: parent ? parent.width : 0
    implicitHeight: 76
    color: mouse.containsMouse ? Theme.subtle : "transparent"
    radius: Theme.radius

    Text {
        id: iconText
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: root.active ? Theme.accent : Theme.foreground
        font.family: root.iconFontFamily
        font.pixelSize: Theme.fontSize
    }

    Column {
        anchors.left: iconText.right
        anchors.leftMargin: 12
        anchors.right: actionLabel.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: root.title
            color: Theme.foreground
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popupFontSize
            font.bold: root.active
        }

        Text {
            width: parent.width
            visible: root.detail !== ""
            text: root.detail
            color: Theme.inactive
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popupSmallFontSize
        }
    }

    Text {
        id: actionLabel
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.busy ? "..." : root.actionText
        color: root.actionEnabled ? Theme.accent : Theme.inactive
        font.family: Theme.fontFamily
        font.pixelSize: Theme.popupSmallFontSize
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.actionEnabled && !root.busy
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
