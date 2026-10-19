import QtQuick
import "../components"
import "../theme"

Item {
    id: root

    property var activeMenu: null
    implicitWidth: Theme.barHeight
    implicitHeight: Theme.barHeight

    function open() {
        if (activeMenu) activeMenu.menuVisible = false
        activeMenu = null
        popup.visible = true
    }

    function openMenu(menu) {
        if (activeMenu) activeMenu.menuVisible = false
        popup.visible = false
        activeMenu = menu
        menu.menuVisible = true
    }

    ModuleButton {
        id: button
        anchors.fill: parent
        icon: "\uf013"
        tooltipText: "Settings"
        hoverFill: true
        onClicked: mouseButton => {
            if (mouseButton !== Qt.LeftButton) return
            if (popup.visible) popup.visible = false
            else if (root.activeMenu && root.activeMenu.menuVisible) {
                root.activeMenu.menuVisible = false
                root.activeMenu = null
            } else root.open()
        }
    }

    ControlPopup {
        id: popup
        anchorItem: root

        PopupHeader {
            title: "Settings"
            action: StyledButton {
                text: "Close"
                onClicked: popup.visible = false
            }
        }

        Grid {
            id: tiles
            width: parent.width
            columns: 3
            spacing: 12
            readonly property real tileWidth: (width - spacing * (columns - 1)) / columns

            SettingsTile {
                width: tiles.tileWidth
                icon: "\uf1eb"
                title: "Wi-Fi"
                iconColor: network.activeDevice ? Theme.network : Theme.inactive
                onClicked: root.openMenu(network)
            }

            SettingsTile {
                width: tiles.tileWidth
                icon: audio.sink && audio.sink.audio && !audio.sink.audio.muted ? "\uf028" : "\uf6a9"
                title: "Sound"
                onClicked: root.openMenu(audio)
            }

            SettingsTile {
                width: tiles.tileWidth
                icon: "\uf293"
                iconFontFamily: Theme.brandFontFamily
                iconColor: bluetooth.adapter && bluetooth.adapter.enabled ? Theme.accent : Theme.inactive
                title: "Bluetooth"
                onClicked: root.openMenu(bluetooth)
            }

            SettingsTile {
                width: tiles.tileWidth
                icon: "\uf108"
                title: "Screen"
                onClicked: root.openMenu(displays)
            }

            SettingsTile {
                width: tiles.tileWidth
                icon: "\uf011"
                title: "Power"
                onClicked: root.openMenu(power)
            }
        }
    }

    Item {
        visible: false

        Network { id: network; settingsPanel: root }
        Audio { id: audio; settingsPanel: root }
        BluetoothWidget { id: bluetooth; settingsPanel: root }
        Displays { id: displays; settingsPanel: root }
        Power { id: power; settingsPanel: root }
    }
}
