pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

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
    property real networkDownloadBytesPerSecond: 0
    property real networkUploadBytesPerSecond: 0
    property var previousNetworkCounters: ({})
    property real previousNetworkTime: 0

    function formatBytes(bytes) {
        var units = ["B", "KiB", "MiB", "GiB", "TiB"]
        var value = Number(bytes)
        var index = 0
        // Step up a unit before 1000 so values never need more than three integer digits
        while (value >= 999.95 && index < units.length - 1) {
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

    function parseNetwork(raw) {
        var now = Date.now()
        var elapsed = (now - root.previousNetworkTime) / 1000
        // Count connected physical links, avoiding loopback and VPN traffic counted twice.
        var interfaces = Networking.devices.values.filter(function(device) {
            return device.connected && (device.type === DeviceType.Wifi || device.type === DeviceType.Wired)
        }).map(function(device) { return device.name })
        var counters = ({})
        var received = 0
        var transmitted = 0
        String(raw || "").split(/\n/).forEach(function(line) {
            var separator = line.indexOf(":")
            if (separator < 0) return
            var name = line.slice(0, separator).trim()
            if (interfaces.indexOf(name) < 0) return
            var fields = line.slice(separator + 1).trim().split(/\s+/)
            if (fields.length < 16) return
            var rx = Number(fields[0])
            var tx = Number(fields[8])
            if (!isFinite(rx) || !isFinite(tx)) return
            counters[name] = { rx: rx, tx: tx }
            var previous = root.previousNetworkCounters[name]
            if (previous) {
                received += Math.max(0, rx - previous.rx)
                transmitted += Math.max(0, tx - previous.tx)
            }
        })
        root.networkDownloadBytesPerSecond = root.previousNetworkTime > 0 && elapsed > 0 ? received / elapsed : 0
        root.networkUploadBytesPerSecond = root.previousNetworkTime > 0 && elapsed > 0 ? transmitted / elapsed : 0
        root.previousNetworkCounters = counters
        root.previousNetworkTime = now
    }

    Process {
        id: networkProcess
        command: ["cat", "/proc/net/dev"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parseNetwork(text)
        }
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
        interval: 1000
        running: true
        repeat: true
        onTriggered: if (!networkProcess.running) networkProcess.running = true
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
