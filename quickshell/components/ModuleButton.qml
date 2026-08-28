import QtQuick
import Quickshell
import "../theme"

Item {
    id: root

    property string icon: ""
    property string label: ""
    property color iconColor: Theme.foreground
    property color labelColor: Theme.foreground
    property string iconFontFamily: Theme.iconFontFamily
    property int horizontalPadding: Theme.modulePadding
    property string tooltipText: ""
    property bool hoverFill: false
    property bool tooltipVisible: false
    readonly property bool hovered: mouse.containsMouse

    signal clicked(int button)
    signal wheelMoved(real delta)

    implicitWidth: content.implicitWidth + horizontalPadding * 2
    implicitHeight: Theme.barHeight

    Rectangle {
        anchors.fill: parent
        color: root.hoverFill && mouse.containsMouse ? Theme.subtle : "transparent"
        radius: Theme.radius
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: root.icon !== "" && root.label !== "" ? 9 : 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            text: root.icon
            color: root.iconColor
            font.family: root.iconFontFamily
            font.pixelSize: Theme.fontSize
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            color: root.labelColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: root.hoverFill ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: event => root.clicked(event.button)
        onWheel: event => root.wheelMoved(event.angleDelta.y)
        onContainsMouseChanged: {
            if (containsMouse && root.tooltipText !== "") tooltipDelay.restart()
            else {
                tooltipDelay.stop()
                root.tooltipVisible = false
            }
        }
    }

    Timer {
        id: tooltipDelay
        interval: 500
        onTriggered: root.tooltipVisible = mouse.containsMouse && root.tooltipText !== ""
    }

    PopupWindow {
        visible: root.tooltipVisible
        implicitWidth: tooltipLabel.implicitWidth + 28
        implicitHeight: 48
        color: "transparent"
        grabFocus: false

        anchor {
            item: root
            edges: Edges.Top
            gravity: Edges.Top
            margins.top: -4
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            border.color: Theme.subtle
            border.width: 1
            radius: Theme.radius

            Text {
                id: tooltipLabel
                anchors.centerIn: parent
                text: root.tooltipText
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
