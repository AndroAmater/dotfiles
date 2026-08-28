pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string diskFree: "--"
    property string diskTooltip: "Disk information unavailable"
    property real memoryAvailableGiB: 0
    property real memoryUsedGiB: 0
    property real memoryTotalGiB: 0
    property int cpuUsage: 0
    property real previousCpuTotal: 0
    property real previousCpuIdle: 0

    function formatBytes(bytes) {
        var units = ["B", "KiB", "MiB", "GiB", "TiB"]
        var value = Number(bytes)
        var index = 0
        while (value >= 1024 && index < units.length - 1) {
            value /= 1024
            index++
        }
        return value.toFixed(index === 0 ? 0 : 1) + units[index]
    }

    function parseDisk(raw) {
        var lines = String(raw || "").trim().split(/\n/)
        if (lines.length < 2) return
        var fields = lines[lines.length - 1].trim().split(/\s+/)
        if (fields.length < 2) return
        var available = Number(fields[0])
        var total = Number(fields[1])
        root.diskFree = root.formatBytes(available)
        root.diskTooltip = root.formatBytes(total - available) + " out of "
            + root.formatBytes(total) + " used ("
            + Math.round((total - available) * 100 / total) + "%)"
    }

    function parseMemory(raw) {
        var values = ({})
        String(raw || "").split(/\n/).forEach(function(line) {
            var match = line.match(/^([A-Za-z_()]+):\s+(\d+)/)
            if (match) values[match[1]] = Number(match[2])
        })
        var total = values.MemTotal || 0
        var available = values.MemAvailable || 0
        root.memoryTotalGiB = total / 1048576
        root.memoryAvailableGiB = available / 1048576
        root.memoryUsedGiB = (total - available) / 1048576
    }

    function parseCpu(raw) {
        var line = String(raw || "").split(/\n/)[0] || ""
        var fields = line.trim().split(/\s+/)
        if (fields[0] !== "cpu" || fields.length < 5) return
        var total = 0
        for (var i = 1; i < fields.length; i++) total += Number(fields[i]) || 0
        var idle = (Number(fields[4]) || 0) + (Number(fields[5]) || 0)
        if (root.previousCpuTotal > 0) {
            var totalDelta = total - root.previousCpuTotal
            var idleDelta = idle - root.previousCpuIdle
            if (totalDelta > 0) root.cpuUsage = Math.round((totalDelta - idleDelta) * 100 / totalDelta)
        }
        root.previousCpuTotal = total
        root.previousCpuIdle = idle
    }

    Process {
        id: diskProcess
        command: ["df", "-B1", "--output=avail,size", "/"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseDisk(text)
        }
    }

    Process {
        id: memoryProcess
        command: ["cat", "/proc/meminfo"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseMemory(text)
        }
    }

    Process {
        id: cpuProcess
        command: ["cat", "/proc/stat"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseCpu(text)
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: if (!diskProcess.running) diskProcess.running = true
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: if (!memoryProcess.running) memoryProcess.running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: if (!cpuProcess.running) cpuProcess.running = true
    }
}
