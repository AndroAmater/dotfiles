import QtQuick
import QtQuick.Controls
import "../theme"

TextField {
    id: root

    color: Theme.foreground
    placeholderTextColor: Theme.inactive
    selectionColor: Theme.accent
    selectedTextColor: Theme.background
    font.family: Theme.fontFamily
    font.pixelSize: Theme.popupFontSize
    leftPadding: 14
    rightPadding: 14
    implicitHeight: 48

    background: Rectangle {
        color: Theme.background
        border.color: root.activeFocus ? Theme.accent : Theme.subtle
        border.width: 1
        radius: Theme.radius
    }
}
