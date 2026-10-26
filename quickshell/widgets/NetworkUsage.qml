import QtQuick
import "../components"
import "../services"
import "../theme"

Row {
    spacing: Theme.moduleSpacing

    ModuleButton {
        icon: "\uf063"
        iconColor: Theme.network
        label: SystemStats.formatBytes(SystemStats.networkDownloadBytesPerSecond).padStart(8) + "/s"
    }

    ModuleButton {
        icon: "\uf062"
        iconColor: Theme.network
        label: SystemStats.formatBytes(SystemStats.networkUploadBytesPerSecond).padStart(8) + "/s"
    }
}
