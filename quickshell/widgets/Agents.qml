import QtQuick
import "../components"
import "../services"
import "../theme"

// AI agent states across all tmux sessions; click to list agents and jump to one
Item {
    id: root

    visible: AgentStatus.working.length + AgentStatus.finished.length + AgentStatus.needsInput.length > 0
    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    Rectangle {
        anchors.fill: parent
        color: hover.hovered ? Theme.subtle : "transparent"
        radius: Theme.radius
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    Row {
        id: row
        anchors.fill: parent

        ModuleButton {
            visible: AgentStatus.needsInput.length > 0
            horizontalPadding: 6
            icon: AgentStatus.icon("needs_input")
            iconColor: AgentStatus.color("needs_input")
            label: String(AgentStatus.needsInput.length)
            tooltipText: "Needs input: " + AgentStatus.sessionNames(AgentStatus.needsInput)
            onClicked: popup.visible = !popup.visible
        }

        ModuleButton {
            horizontalPadding: 6
            icon: AgentStatus.icon("working")
            iconColor: AgentStatus.color("working")
            iconSpinning: AgentStatus.working.length > 0
            label: String(AgentStatus.working.length)
            tooltipText: AgentStatus.working.length > 0
                ? "Working: " + AgentStatus.sessionNames(AgentStatus.working) : "No agents working"
            onClicked: popup.visible = !popup.visible
        }

        ModuleButton {
            visible: AgentStatus.finished.length > 0
            horizontalPadding: 6
            icon: AgentStatus.icon("finished")
            iconColor: AgentStatus.color("finished")
            label: String(AgentStatus.finished.length)
            tooltipText: "Finished: " + AgentStatus.sessionNames(AgentStatus.finished)
            onClicked: popup.visible = !popup.visible
        }
    }

    ControlPopup {
        id: popup
        anchorItem: root

        PopupHeader {
            title: "Agents"
            subtitle: AgentStatus.agents.length + (AgentStatus.agents.length === 1 ? " agent" : " agents")
                + " across tmux sessions"
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.subtle
        }

        ListView {
            id: agentList
            width: parent.width
            height: Math.min(contentHeight, 530)
            clip: true
            spacing: 2
            model: AgentStatus.agents

            delegate: DeviceRow {
                required property var modelData
                width: agentList.width
                icon: AgentStatus.icon(modelData.status)
                iconColor: AgentStatus.color(modelData.status)
                title: modelData.sessionName
                detail: modelData.title !== "" ? modelData.title : AgentStatus.providerName(modelData.provider)
                actionText: AgentStatus.label(modelData.status)
                onClicked: {
                    popup.visible = false
                    AgentStatus.focus(modelData)
                }
            }
        }
    }
}
