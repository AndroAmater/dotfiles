import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../components"
import "../theme"

Scope {
    id: controller

    property bool opened: false

    function toggle(): void {
        opened = !opened
    }

    function close(): void {
        opened = false
    }

    function launchCount(entry): int {
        return Number(usageData.counts[entry.id] || 0)
    }

    function recordLaunch(entry): void {
        var updatedCounts = Object.assign({}, usageData.counts)
        updatedCounts[entry.id] = launchCount(entry) + 1
        usageData.counts = updatedCounts
    }

    FileView {
        id: usageFile
        path: Quickshell.stateDir + "/launcher-usage.json"
        printErrors: false
        blockLoading: true
        blockWrites: true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: writeAdapter()

        JsonAdapter {
            id: usageData
            property var counts: ({})
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            controller.toggle()
        }

        function close(): void {
            controller.close()
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property var modelData
            property int selectedIndex: 0
            readonly property bool onFocusedMonitor: Hyprland.focusedMonitor !== null
                && Hyprland.focusedMonitor.name === modelData.name
            readonly property var applications: {
                usageData.counts
                return filteredApplications(searchField.text)
            }

            function searchText(entry): string {
                return [
                    entry.name,
                    entry.genericName,
                    entry.comment,
                    entry.keywords.join(" ")
                ].join(" ").toLowerCase()
            }

            function matchScore(entry, query): int {
                var name = entry.name.toLowerCase()
                if (name === query) return 0
                if (name.startsWith(query)) return 1
                if (name.split(/\s+/).some(function(word) { return word.startsWith(query) })) return 2
                if (name.includes(query)) return 3
                if (entry.genericName.toLowerCase().includes(query)) return 4
                return 5
            }

            function filteredApplications(query): var {
                var normalized = query.trim().toLowerCase()
                var applications = DesktopEntries.applications.values.slice()

                if (normalized !== "") {
                    var terms = normalized.split(/\s+/)
                    applications = applications.filter(function(entry) {
                        var searchable = window.searchText(entry)
                        return terms.every(function(term) { return searchable.includes(term) })
                    })
                }

                return applications.sort(function(left, right) {
                    if (normalized !== "") {
                        var scoreDifference = window.matchScore(left, normalized)
                            - window.matchScore(right, normalized)
                        if (scoreDifference !== 0) return scoreDifference
                    }

                    var usageDifference = controller.launchCount(right)
                        - controller.launchCount(left)
                    if (usageDifference !== 0) return usageDifference
                    return left.name.localeCompare(right.name)
                })
            }

            function moveSelection(offset): void {
                if (applications.length === 0) return
                selectedIndex = (selectedIndex + offset + applications.length)
                    % applications.length
                results.positionViewAtIndex(selectedIndex, ListView.Contain)
            }

            function launchSelected(): void {
                if (selectedIndex < 0 || selectedIndex >= applications.length) return
                var entry = applications[selectedIndex]
                controller.recordLaunch(entry)
                controller.close()
                entry.execute()
            }

            screen: modelData
            visible: controller.opened && onFocusedMonitor
            color: "transparent"
            focusable: true
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quickshell-launcher"

            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            onVisibleChanged: {
                if (!visible) {
                    selectedIndex = 0
                    results.cancelFlick()
                    results.positionViewAtBeginning()
                    return
                }
                searchField.text = ""
                selectedIndex = 0
                Qt.callLater(function() { searchField.forceActiveFocus() })
            }

            Rectangle {
                anchors.fill: parent
                color: "#99000000"

                MouseArea {
                    anchors.fill: parent
                    onClicked: controller.close()
                }

                Rectangle {
                    id: card
                    anchors.centerIn: parent
                    width: Math.min(920, parent.width - 48)
                    height: Math.min(860, parent.height - 96)
                    color: Theme.background
                    border.color: Theme.subtle
                    border.width: Theme.popupBorderWidth
                    radius: Theme.radius

                    MouseArea {
                        anchors.fill: parent
                    }

                    Item {
                        id: searchBar
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: 88

                        Text {
                            id: searchIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf002"
                            color: searchField.activeFocus ? Theme.accent : Theme.inactive
                            font.family: Theme.awesomeFontFamily
                            font.pixelSize: 28
                        }

                        StyledTextField {
                            id: searchField
                            anchors.left: searchIcon.right
                            anchors.leftMargin: 16
                            anchors.right: parent.right
                            anchors.rightMargin: 24
                            anchors.verticalCenter: parent.verticalCenter
                            placeholderText: "Search applications..."
                            background: Item {}

                            onTextChanged: {
                                window.selectedIndex = 0
                                Qt.callLater(function() {
                                    results.cancelFlick()
                                    results.positionViewAtBeginning()
                                })
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Down) {
                                    window.moveSelection(1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Up) {
                                    window.moveSelection(-1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    window.launchSelected()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    controller.close()
                                    event.accepted = true
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: searchBar.bottom
                        height: 1
                        color: Theme.subtle
                    }

                    ListView {
                        id: results
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: searchBar.bottom
                        anchors.bottom: footer.top
                        anchors.topMargin: 1
                        clip: true
                        model: window.applications
                        highlightFollowsCurrentItem: false
                        boundsBehavior: Flickable.StopAtBounds
                        boundsMovement: Flickable.StopAtBounds

                        onCountChanged: {
                            if (count === 0) window.selectedIndex = -1
                            else if (window.selectedIndex < 0 || window.selectedIndex >= count)
                                window.selectedIndex = 0
                        }

                        delegate: Rectangle {
                            id: applicationRow

                            required property var modelData
                            required property int index

                            width: ListView.view.width
                            height: 76
                            color: index === window.selectedIndex || rowMouse.containsMouse
                                ? Theme.subtle : "transparent"

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 4
                                visible: applicationRow.index === window.selectedIndex
                                color: Theme.accent
                            }

                            IconImage {
                                id: applicationIcon
                                readonly property bool available: applicationRow.modelData.icon !== ""
                                    && Quickshell.hasThemeIcon(applicationRow.modelData.icon)

                                anchors.left: parent.left
                                anchors.leftMargin: 24
                                anchors.verticalCenter: parent.verticalCenter
                                implicitSize: 42
                                visible: available
                                source: available
                                    ? Quickshell.iconPath(applicationRow.modelData.icon) : ""
                            }

                            Text {
                                anchors.centerIn: applicationIcon
                                visible: !applicationIcon.available
                                text: "\uf1b2"
                                color: Theme.inactive
                                font.family: Theme.awesomeFontFamily
                                font.pixelSize: 34
                            }

                            Column {
                                anchors.left: applicationIcon.right
                                anchors.leftMargin: 18
                                anchors.right: parent.right
                                anchors.rightMargin: 24
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: applicationRow.modelData.name
                                    color: Theme.foreground
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.popupFontSize
                                    font.bold: applicationRow.index === window.selectedIndex
                                }

                                Text {
                                    width: parent.width
                                    text: applicationRow.modelData.genericName !== ""
                                        ? applicationRow.modelData.genericName
                                        : applicationRow.modelData.comment
                                    visible: text !== ""
                                    color: Theme.inactive
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.popupSmallFontSize
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    window.selectedIndex = applicationRow.index
                                    window.launchSelected()
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: results.count === 0
                            text: "No matching applications"
                            color: Theme.inactive
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popupFontSize
                        }
                    }

                    Rectangle {
                        id: footer
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 52
                        color: Theme.background
                        border.color: Theme.subtle
                        border.width: 1

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: results.count + (results.count === 1 ? " application" : " applications")
                            color: Theme.inactive
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popupSmallFontSize
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: "up/down navigate   enter launch   esc close"
                            color: Theme.inactive
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popupSmallFontSize
                        }
                    }
                }
            }
        }
    }
}
