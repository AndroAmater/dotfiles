import QtQuick
import "../widgets"
import "../theme"

Row {
    spacing: Theme.moduleSpacing

    Resources {}
    Network {}
    Audio {}
    BluetoothWidget {}
    Backlight {}
    Battery {}
    Displays {}
    Tray {}
    Power {}
}
