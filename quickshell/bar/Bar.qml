import QtQuick
import Quickshell
import "../theme"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData

            screen: modelData
            color: Theme.background
            implicitHeight: Theme.barHeight
            exclusiveZone: Theme.barHeight
            aboveWindows: true

            anchors {
                left: true
                right: true
                bottom: true
            }

            LeftModules {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
            }

            CenterModules {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.bottom: parent.bottom
            }

            RightModules {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
            }
        }
    }
}
