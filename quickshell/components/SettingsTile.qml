import QtQuick
import "../theme"

Rectangle {
    id: root

    required property string icon
    required property string title
    property string iconFontFamily: Theme.awesomeFontFamily
    property color iconColor: Theme.foreground
    signal clicked()

    implicitHeight: 124
    color: mouse.containsMouse ? Theme.subtle : Theme.background
    border.color: Theme.subtle
    border.width: 1
    radius: Theme.radius

    Column {
        anchors.centerIn: parent
        spacing: 14

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            color: root.iconColor
            font.family: root.iconFontFamily
            font.pixelSize: 36
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.title
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popupSmallFontSize
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
