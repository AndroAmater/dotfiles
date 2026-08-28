import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../components"
import "../theme"

Item {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property int volumePercent: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0

    implicitWidth: button.implicitWidth
    implicitHeight: Theme.barHeight

    function setVolume(value) {
        if (!sink || !sink.audio) return
        sink.audio.volume = Math.max(0, Math.min(1.5, value))
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    ModuleButton {
        id: button
        anchors.fill: parent
        icon: !root.sink || !root.sink.audio || root.sink.audio.muted ? "\uf6a9"
            : root.volumePercent >= 50 ? "\uf028"
            : root.volumePercent > 0 ? "\uf027" : "\uf026"
        label: root.sink && root.sink.audio && root.sink.audio.muted
            ? "muted" : root.volumePercent + "%"
        tooltipText: root.sink ? root.sink.description : "No audio output"
        hoverFill: true
        onClicked: mouseButton => {
            if (mouseButton === Qt.LeftButton) popup.visible = !popup.visible
            else if (mouseButton === Qt.RightButton && root.sink && root.sink.audio)
                root.sink.audio.muted = !root.sink.audio.muted
        }
        onWheelMoved: delta => root.setVolume((root.sink && root.sink.audio ? root.sink.audio.volume : 0)
            + (delta > 0 ? 0.05 : -0.05))
    }

    ControlPopup {
        id: popup
        anchorItem: root
        PopupHeader {
            title: "Audio"
            subtitle: root.sink ? root.sink.description : "No output device"
            action: StyledButton {
                text: root.sink && root.sink.audio && root.sink.audio.muted ? "Unmute" : "Mute"
                active: root.sink && root.sink.audio && root.sink.audio.muted
                enabled: root.sink !== null && root.sink.audio !== null
                onClicked: root.sink.audio.muted = !root.sink.audio.muted
            }
        }

        SectionTitle { text: "OUTPUT VOLUME" }

        Row {
            width: parent.width
            spacing: 10

            Text {
                width: 28
                text: root.sink && root.sink.audio && root.sink.audio.muted ? "\uf6a9" : "\uf028"
                color: Theme.foreground
                font.family: Theme.awesomeFontFamily
                font.pixelSize: Theme.fontSize
            }

            StyledSlider {
                width: parent.width - 88
                to: 1.5
                value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
                enabled: root.sink !== null
                onMoved: root.setVolume(value)
            }

            Text {
                width: 40
                text: root.volumePercent + "%"
                color: Theme.foreground
                horizontalAlignment: Text.AlignRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popupSmallFontSize
            }
        }

        SectionTitle { text: "OUTPUT DEVICE" }

        ListView {
            id: sinkList
            width: parent.width
            height: 170
            clip: true
            spacing: 2
            model: Pipewire.nodes.values.filter(function(node) {
                return node.audio !== null && node.isSink && !node.isStream
            })
            delegate: DeviceRow {
                required property var modelData
                width: sinkList.width
                icon: "\uf028"
                title: modelData.description || modelData.nickname || modelData.name
                detail: modelData === root.sink ? "Default output" : ""
                actionText: modelData === root.sink ? "Active" : "Use"
                active: modelData === root.sink
                onClicked: Pipewire.preferredDefaultAudioSink = modelData
            }
        }

        SectionTitle { text: "INPUT DEVICE" }

        ListView {
            id: sourceList
            width: parent.width
            height: 170
            clip: true
            spacing: 2
            model: Pipewire.nodes.values.filter(function(node) {
                return node.audio !== null && !node.isSink && !node.isStream
            })
            delegate: DeviceRow {
                required property var modelData
                width: sourceList.width
                icon: "\uf130"
                title: modelData.description || modelData.nickname || modelData.name
                detail: modelData === root.source ? "Default input" : ""
                actionText: modelData === root.source ? "Active" : "Use"
                active: modelData === root.source
                onClicked: Pipewire.preferredDefaultAudioSource = modelData
            }
        }
    }
}
