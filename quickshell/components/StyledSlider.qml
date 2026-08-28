import QtQuick
import QtQuick.Controls
import "../theme"

Slider {
    id: root

    from: 0
    to: 1
    stepSize: 0.01
    implicitHeight: 40

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 6
        color: Theme.subtle

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            color: Theme.accent
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: 20
        implicitHeight: 30
        color: root.pressed ? Theme.foreground : Theme.accent
        radius: Theme.radius
    }
}
