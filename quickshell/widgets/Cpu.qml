import QtQuick
import "../components"
import "../services"
import "../theme"

ModuleButton {
    id: root

    icon: "\uf2db"
    iconFontFamily: Theme.awesomeFontFamily
    iconColor: Theme.cpu
    label: SystemStats.cpuUsage + "%"
    tooltipText: ""

}
