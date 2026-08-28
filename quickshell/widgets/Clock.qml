import QtQuick
import Quickshell
import "../components"

ModuleButton {
    readonly property SystemClock clock: SystemClock {
        precision: SystemClock.Minutes
    }

    label: " " + Qt.formatDateTime(clock.date, "yyyy-MM-dd HH:mm")
    tooltipText: label
}
