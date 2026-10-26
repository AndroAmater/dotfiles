import QtQuick
import "../services"
import "../theme"

// Alert for an agent that finished or needs input; click to jump to its tmux pane
Rectangle {
    id: card

    required property int index
    required property string status
    required property string sessionName
    required property string provider
    required property string title
    readonly property color statusColor: AgentStatus.color(status)

    signal dismissAll()

    implicitHeight: content.implicitHeight + 36
    color: Theme.background
    border.color: statusColor
    border.width: Theme.popupBorderWidth
    radius: Theme.radius

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 4
        color: card.statusColor
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton) card.dismissAll()
            else AgentStatus.openAlert(card.index)
        }
    }

    Row {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 22
        anchors.rightMargin: 18
        anchors.topMargin: 18
        spacing: 14

        Item {
            id: iconFrame
            width: 48
            height: 48

            Text {
                anchors.centerIn: parent
                text: AgentStatus.icon(card.status)
                color: card.statusColor
                font.family: Theme.awesomeFontFamily
                font.pixelSize: 32
            }
        }

        Column {
            width: parent.width - iconFrame.width - closeButton.width - parent.spacing * 2
            spacing: 4

            Text {
                width: parent.width
                text: AgentStatus.providerName(card.provider).toUpperCase()
                color: card.statusColor
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.bold: true
            }

            Text {
                width: parent.width
                text: AgentStatus.label(card.status) + " · " + card.sessionName
                color: card.statusColor
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
                text: card.title
                color: Theme.inactive
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: 18
            }
        }

        Rectangle {
            id: closeButton
            width: 36
            height: 36
            color: closeMouse.containsMouse ? Theme.subtle : "transparent"
            radius: Theme.radius

            Text {
                anchors.centerIn: parent
                text: ""
                color: card.statusColor
                font.family: Theme.awesomeFontFamily
                font.pixelSize: 18
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: AgentStatus.dismissAlert(card.index)
            }
        }
    }
}
