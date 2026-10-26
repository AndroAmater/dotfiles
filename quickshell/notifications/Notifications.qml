import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../services"
import "../theme"

Scope {
    id: root

    readonly property int maxVisible: 5

    function dismissAll(): void {
        var notifications = server.trackedNotifications.values.slice()
        for (var index = 0; index < notifications.length; index++)
            notifications[index].dismiss()
        AgentStatus.dismissAllAlerts()
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

            // Agent alerts sit below regular notifications, closest to the bar
            readonly property int maxHeight: modelData.height - Theme.barHeight - 20
            readonly property int listGap: notificationList.count > 0 && alertList.count > 0 ? 8 : 0

            screen: modelData
            visible: (server.trackedNotifications.values.length > 0 || AgentStatus.alerts.count > 0)
                && onFocusedMonitor
            implicitWidth: Math.min(Theme.popupWidth, modelData.width - 24)
            implicitHeight: Math.max(1, Math.min(
                notificationList.contentHeight + listGap + alertList.contentHeight, maxHeight))
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

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Math.max(0, Math.min(contentHeight,
                    window.maxHeight - window.listGap - alertList.contentHeight))
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

            ListView {
                id: alertList

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.min(contentHeight, window.maxHeight)
                model: AgentStatus.alerts
                spacing: 8
                interactive: false

                delegate: AgentAlertCard {
                    width: alertList.width
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
