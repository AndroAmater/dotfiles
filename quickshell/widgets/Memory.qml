import QtQuick
import "../components"
import "../services"
import "../theme"

ModuleButton {
    id: root

    icon: "\uf538"
    iconFontFamily: Theme.awesomeFontFamily
    iconColor: Theme.memory
    label: SystemStats.memoryUsedGiB.toFixed(1) + " GiB"
    tooltipText: ""

}
