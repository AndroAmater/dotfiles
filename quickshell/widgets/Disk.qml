import QtQuick
import "../components"
import "../services"
import "../theme"

ModuleButton {
    id: root

    icon: "\uf0a0"
    iconFontFamily: Theme.awesomeFontFamily
    iconColor: Theme.disk
    // Padded to "999.9GiB" so the width stays constant
    label: SystemStats.diskFree.padStart(8)
    tooltipText: ""

}
