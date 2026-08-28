import QtQuick
import Quickshell
import "../theme"

PopupWindow {
    id: root

    required property Item anchorItem
    property int popupHeight: content.implicitHeight + Theme.popupPadding * 2
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
            id: content
            anchors.fill: parent
            anchors.margins: Theme.popupPadding
            spacing: Theme.popupSpacing
        }
    }
}
