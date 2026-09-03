import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../theme"

Scope {
    id: root

    readonly property int maxVisible: 5

    function dismissAll(): void {
        var notifications = server.trackedNotifications.values.slice()
        for (var index = 0; index < notifications.length; index++)
            notifications[index].dismiss()
    }

    function trimOverflow(): void {
        while (server.trackedNotifications.values.length > maxVisible)
            server.trackedNotifications.values[0].dismiss()
    }

    NotificationServer {
        id: server

        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true
            Qt.callLater(root.trimOverflow)
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            readonly property bool onFocusedMonitor: Hyprland.focusedMonitor !== null
                ? Hyprland.focusedMonitor.name === modelData.name
                : Quickshell.screens.length > 0 && Quickshell.screens[0].name === modelData.name

            screen: modelData
            visible: server.trackedNotifications.values.length > 0 && onFocusedMonitor
            implicitWidth: Math.min(Theme.popupWidth, modelData.width - 24)
            implicitHeight: Math.max(1, Math.min(notificationList.contentHeight,
                modelData.height - Theme.barHeight - 20))
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-notifications"

            anchors {
                right: true
                bottom: true
            }

            margins {
                right: 10
                bottom: Theme.barHeight + 10
            }

            ListView {
                id: notificationList

                anchors.fill: parent
                model: server.trackedNotifications
                spacing: 8
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: NotificationCard {
                    required property var modelData
                    width: notificationList.width
                    notification: modelData
                    active: window.onFocusedMonitor
                    onDismissAll: root.dismissAll()
                }

                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
                }

                remove: Transition {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 120 }
                }
            }
        }
    }
}
