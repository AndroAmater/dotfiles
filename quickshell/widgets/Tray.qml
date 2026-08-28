import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../theme"

Row {
    id: root
    spacing: 8
    leftPadding: SystemTray.items.values.length > 0 ? Theme.modulePadding : 0
    rightPadding: 0
    height: Theme.barHeight

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem
            required property var modelData
            width: 24
            height: Theme.barHeight

            IconImage {
                anchors.centerIn: parent
                implicitWidth: 22
                implicitHeight: 22
                source: trayItem.modelData.icon
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: event => {
                    if (event.button === Qt.LeftButton && !trayItem.modelData.onlyMenu)
                        trayItem.modelData.activate()
                    else if (event.button === Qt.MiddleButton)
                        trayItem.modelData.secondaryActivate()
                    else {
                        var point = trayItem.mapToItem(trayItem.QsWindow.window.contentItem, event.x, event.y)
                        trayItem.modelData.display(trayItem.QsWindow.window, point.x, point.y)
                    }
                }
                onWheel: event => trayItem.modelData.scroll(event.angleDelta.y, false)
            }
        }
    }
}
