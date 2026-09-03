import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../components"
import "../theme"

Rectangle {
    id: card

    required property var notification
    property bool active: true
    readonly property bool critical: notification !== null
        && notification.urgency === NotificationUrgency.Critical
    readonly property string iconSource: {
        if (notification === null) return ""
        if (notification.image !== "") return notification.image
        if (notification.appIcon === "") return ""
        if (notification.appIcon.startsWith("/")
                || notification.appIcon.startsWith("file:")
                || notification.appIcon.startsWith("image:")) return notification.appIcon
        return Quickshell.hasThemeIcon(notification.appIcon)
            ? Quickshell.iconPath(notification.appIcon) : ""
    }

    signal dismissAll()

    implicitHeight: content.implicitHeight + 36
    color: Theme.background
    border.color: critical ? Theme.urgent : Theme.subtle
    border.width: Theme.popupBorderWidth
    radius: Theme.radius

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 4
        color: card.critical ? Theme.urgent : Theme.accent
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton) card.dismissAll()
            else if (card.notification !== null) card.notification.dismiss()
        }
    }

    Column {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 22
        anchors.rightMargin: 18
        anchors.topMargin: 18
        spacing: 12

        Row {
            width: parent.width
            spacing: 14

            Item {
                id: iconFrame
                width: 48
                height: 48

                IconImage {
                    anchors.fill: parent
                    visible: card.iconSource !== ""
                    source: card.iconSource
                }

                Text {
                    anchors.centerIn: parent
                    visible: card.iconSource === ""
                    text: "\uf0f3"
                    color: card.critical ? Theme.urgent : Theme.accent
                    font.family: Theme.awesomeFontFamily
                    font.pixelSize: 32
                }
            }

            Column {
                width: parent.width - iconFrame.width - closeButton.width - parent.spacing * 2
                spacing: 4

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: card.notification !== null
                        ? card.notification.appName.toUpperCase() : ""
                    color: card.critical ? Theme.urgent : Theme.accent
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: card.notification !== null && card.notification.summary !== ""
                        ? card.notification.summary : "Notification"
                    color: card.critical ? Theme.urgent : Theme.foreground
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popupTitleFontSize
                    font.bold: true
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: card.notification !== null ? card.notification.body : ""
                    textFormat: Text.StyledText
                    color: Theme.inactive
                    linkColor: Theme.accent
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }

            Rectangle {
                id: closeButton
                width: 36
                height: 36
                color: closeMouse.containsMouse ? Theme.subtle : "transparent"
                border.color: closeMouse.containsMouse ? Theme.subtle : "transparent"
                border.width: 1
                radius: Theme.radius

                Text {
                    anchors.centerIn: parent
                    text: "\uf00d"
                    color: card.critical ? Theme.urgent : Theme.inactive
                    font.family: Theme.awesomeFontFamily
                    font.pixelSize: 18
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (card.notification !== null) card.notification.dismiss()
                    }
                }
            }
        }

        Flow {
            width: parent.width
            spacing: 8
            visible: card.notification !== null && card.notification.actions.length > 0

            Repeater {
                model: card.notification !== null ? card.notification.actions : []

                StyledButton {
                    required property var modelData
                    text: modelData.text
                    onClicked: modelData.invoke()
                }
            }
        }
    }

    Timer {
        readonly property int requestedTimeout: card.notification !== null
            && card.notification.expireTimeout > 0
            ? card.notification.expireTimeout * 1000 : 0
        readonly property int defaultTimeout: card.notification !== null
            && card.notification.urgency === NotificationUrgency.Low
            ? 2000 : 5000

        interval: requestedTimeout > 0 ? requestedTimeout : defaultTimeout
        running: card.active && card.notification !== null && card.notification.expireTimeout !== 0
            && !card.critical && !cardMouse.containsMouse
        onTriggered: {
            if (card.notification !== null) card.notification.expire()
        }
    }
}
