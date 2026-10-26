pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

// AI agents across all tmux sessions, as reported by tmux-agents.
// Raises an alert when an agent stops working because it finished or needs input.
Singleton {
    id: root

    readonly property var statusOrder: ["needs_input", "finished", "working", "unknown", "inactive"]
    readonly property int maxAlerts: 5

    // One entry per agent: { key, status, sessionId, sessionName, paneId, provider, title }
    property var agents: []
    readonly property var working: agents.filter(agent => agent.status === "working")
    readonly property var finished: agents.filter(agent => agent.status === "finished")
    readonly property var needsInput: agents.filter(agent => agent.status === "needs_input")
    readonly property ListModel alerts: ListModel {}

    // Last known status per agent, ignoring transient "unknown" reads
    property var lastStatuses: ({})
    property string currentSession: ""

    function icon(status) {
        return status === "needs_input" ? ""
            : status === "finished" ? ""
            : status === "working" ? ""
            : status === "inactive" ? ""
            : ""
    }

    function color(status) {
        return status === "needs_input" ? Theme.urgent
            : status === "finished" ? Theme.network
            : status === "working" ? Theme.accent
            : Theme.inactive
    }

    function label(status) {
        return status === "needs_input" ? "Needs input"
            : status === "finished" ? "Finished"
            : status === "working" ? "Working"
            : status === "inactive" ? "Inactive"
            : "Unknown"
    }

    function providerName(provider) {
        return provider === "opencode" ? "OpenCode" : provider === "claude" ? "Claude Code" : provider
    }

    function sessionNames(list) {
        return list.map(agent => agent.sessionName).join(", ")
    }

    function focus(agent) {
        Quickshell.execDetached([Quickshell.shellPath("scripts/focus-tmux-agent.sh"), agent.sessionId, agent.paneId])
    }

    function openAlert(index) {
        focus(alerts.get(index))
        alerts.remove(index)
    }

    function dismissAlert(index) {
        alerts.remove(index)
    }

    function dismissAllAlerts() {
        alerts.clear()
    }

    function raiseAlert(agent, status) {
        removeAlerts(alert => alert.key === agent.key)
        alerts.append({
            key: agent.key,
            status: status,
            sessionId: agent.sessionId,
            sessionName: agent.sessionName,
            paneId: agent.paneId,
            provider: agent.provider,
            title: agent.title
        })
        while (alerts.count > maxAlerts) alerts.remove(0)
    }

    function removeAlerts(predicate) {
        for (var index = alerts.count - 1; index >= 0; index--) {
            if (predicate(alerts.get(index))) alerts.remove(index)
        }
    }

    function parse(raw) {
        var data
        try {
            data = JSON.parse(raw)
        } catch (e) {
            // No tmux server or binary missing; treat as no agents
            data = { sessions: [] }
        }

        var next = []
        var sessions = data.sessions || []
        for (var i = 0; i < sessions.length; i++) {
            var sessionAgents = sessions[i].agents || []
            for (var j = 0; j < sessionAgents.length; j++) {
                var agent = sessionAgents[j]
                next.push({
                    key: agent.pid + agent.pane_id,
                    status: agent.state,
                    sessionId: sessions[i].id,
                    sessionName: sessions[i].name,
                    paneId: agent.pane_id,
                    provider: agent.provider,
                    title: agent.title || ""
                })
            }
        }
        next.sort((a, b) => statusOrder.indexOf(a.status) - statusOrder.indexOf(b.status)
            || a.sessionName.localeCompare(b.sessionName))
        if (JSON.stringify(next) !== JSON.stringify(agents)) agents = next

        var statuses = {}
        var raised = []
        for (var k = 0; k < next.length; k++) {
            var previous = lastStatuses[next[k].key]
            var status = next[k].status === "unknown" && previous !== undefined ? previous : next[k].status
            statuses[next[k].key] = status
            if (previous === "working" && (status === "finished" || status === "needs_input"))
                raised.push({ agent: next[k], status: status })
        }
        lastStatuses = statuses

        // Drop alerts the user already acted on: the agent moved on, or they switched to its session
        var switchedTo = data.current_session && data.current_session !== currentSession
            ? data.current_session : ""
        currentSession = data.current_session || ""
        removeAlerts(alert => statuses[alert.key] !== alert.status || alert.sessionId === switchedTo)

        for (var r = 0; r < raised.length; r++) raiseAlert(raised[r].agent, raised[r].status)
    }

    Process {
        id: statusProcess
        command: ["sh", "-c",
            "exec \"${TMUX_AGENTS_BIN:-$HOME/Documents/Projects/tmux-agents/target/release/tmux-agents}\" list --json"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: if (!statusProcess.running) statusProcess.running = true
    }
}
