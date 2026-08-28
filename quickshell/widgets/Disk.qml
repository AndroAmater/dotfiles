import QtQuick
import "../components"
import "../services"
import "../theme"

ModuleButton {
    id: root

    icon: "\uf0a0"
    iconFontFamily: Theme.awesomeFontFamily
    iconColor: Theme.disk
    label: SystemStats.diskFree
    tooltipText: ""

}
