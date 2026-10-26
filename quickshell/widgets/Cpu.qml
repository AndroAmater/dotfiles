import QtQuick
import "../components"
import "../services"
import "../theme"

ModuleButton {
    id: root

    icon: "\uf2db"
    iconFontFamily: Theme.awesomeFontFamily
    iconColor: Theme.cpu
    label: String(SystemStats.cpuUsage).padStart(2) + "%"
    tooltipText: ""

}
