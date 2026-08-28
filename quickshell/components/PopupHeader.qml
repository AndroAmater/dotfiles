import QtQuick
import "../theme"

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property alias action: actionSlot.data

    width: parent ? parent.width : 0
    implicitHeight: subtitle === "" ? 46 : 70

    Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            text: root.title
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popupTitleFontSize
            font.bold: true
        }

        Text {
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Theme.inactive
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popupSmallFontSize
        }
    }

    Item {
        id: actionSlot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
