import QtQuick
import "../components"
import "../theme"

Item {
    id: root

    implicitWidth: indicators.implicitWidth
    implicitHeight: Theme.barHeight

    Rectangle {
        anchors.fill: parent
        color: groupMouse.containsMouse ? Theme.subtle : "transparent"
        radius: Theme.radius
    }

    Row {
        id: indicators
        anchors.fill: parent
        spacing: Theme.moduleSpacing

        Disk {}
        Memory {}
        Cpu {}
    }

    MouseArea {
        id: groupMouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: preview.visible = !preview.visible
    }

    ResourcePreview {
        id: preview
        anchorItem: root
    }
}
