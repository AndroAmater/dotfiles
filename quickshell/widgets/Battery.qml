import QtQuick
import Quickshell.Services.UPower
import "../components"
import "../theme"

ModuleButton {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property int capacity: battery.ready ? Math.round(battery.percentage * 100) : 0
    readonly property bool charging: battery.ready && battery.changeRate > 0
    readonly property bool full: battery.ready && capacity >= 99 && !UPower.onBattery

    visible: battery.ready && battery.isLaptopBattery && battery.isPresent
    implicitWidth: visible ? 112 : 0
    icon: charging ? "\uf0e7"
        : capacity <= 10 ? "\uf244"
        : capacity <= 35 ? "\uf243"
        : capacity <= 65 ? "\uf242"
        : capacity <= 90 ? "\uf241"
        : "\uf240"
    label: full ? "full" : capacity + "%"
    labelColor: capacity <= 15 ? Theme.urgent : Theme.foreground
    tooltipText: "Battery: " + capacity + "%"
}
