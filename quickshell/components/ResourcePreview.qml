import QtQuick
import Quickshell
import "../services"
import "../theme"

PopupWindow {
    id: root

    required property Item anchorItem
    readonly property int terminalFontSize: 19

    function escapeHtml(value) {
        return value.replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
    }

    function indexedColor(index) {
        var basic = [
            "#000000", "#800000", "#008000", "#808000",
            "#000080", "#800080", "#008080", "#c0c0c0",
            "#808080", "#ff0000", "#00ff00", "#ffff00",
            "#0000ff", "#ff00ff", "#00ffff", "#ffffff"
        ]
        if (index < 16) return basic[index]
        if (index < 232) {
            var value = index - 16
            var levels = [0, 95, 135, 175, 215, 255]
            var red = levels[Math.floor(value / 36)]
            var green = levels[Math.floor(value / 6) % 6]
            var blue = levels[value % 6]
            return "#" + red.toString(16).padStart(2, "0")
                + green.toString(16).padStart(2, "0")
                + blue.toString(16).padStart(2, "0")
        }
        var gray = 8 + (index - 232) * 10
        var channel = gray.toString(16).padStart(2, "0")
        return "#" + channel + channel + channel
    }

    function ansiToHtml(value) {
        if (value === "") return "<pre>Starting btop...</pre>"

        var foreground = ""
        var background = ""
        var bold = false
        var result = "<pre style=\"margin:0; font-family:'" + Theme.fontFamily
            + "'; font-size:" + terminalFontSize + "px; color:" + Theme.foreground + "\">"
        var cursor = 0
        var expression = /\x1b\[([0-9;:]*)m/g
        var match

        function closeSpan() {
            if (foreground !== "" || background !== "" || bold) result += "</span>"
        }

        function openSpan() {
            var styles = []
            if (foreground !== "") styles.push("color:" + foreground)
            if (background !== "") styles.push("background-color:" + background)
            if (bold) styles.push("font-weight:bold")
            if (styles.length > 0) result += "<span style=\"" + styles.join(";") + "\">"
        }

        while ((match = expression.exec(value)) !== null) {
            result += escapeHtml(value.substring(cursor, match.index))
            closeSpan()

            var parameters = match[1] === "" ? [0] : match[1].replace(/:/g, ";").split(";").map(Number)
            for (var index = 0; index < parameters.length; ++index) {
                var code = parameters[index]
                if (code === 0) {
                    foreground = ""
                    background = ""
                    bold = false
                } else if (code === 1) {
                    bold = true
                } else if (code === 22) {
                    bold = false
                } else if (code >= 30 && code <= 37) {
                    foreground = indexedColor(code - 30)
                } else if (code >= 90 && code <= 97) {
                    foreground = indexedColor(code - 90 + 8)
                } else if (code === 39) {
                    foreground = ""
                } else if (code >= 40 && code <= 47) {
                    background = indexedColor(code - 40)
                } else if (code >= 100 && code <= 107) {
                    background = indexedColor(code - 100 + 8)
                } else if (code === 49) {
                    background = ""
                } else if ((code === 38 || code === 48) && parameters[index + 1] === 2) {
                    var color = "#" + parameters[index + 2].toString(16).padStart(2, "0")
                        + parameters[index + 3].toString(16).padStart(2, "0")
                        + parameters[index + 4].toString(16).padStart(2, "0")
                    if (code === 38) foreground = color
                    else background = color
                    index += 4
                } else if ((code === 38 || code === 48) && parameters[index + 1] === 5) {
                    var indexed = indexedColor(parameters[index + 2])
                    if (code === 38) foreground = indexed
                    else background = indexed
                    index += 2
                }
            }

            openSpan()
            cursor = expression.lastIndex
        }

        result += escapeHtml(value.substring(cursor))
        closeSpan()
        return result + "</pre>"
    }

    implicitWidth: Math.max(Theme.popupWidth, terminalText.implicitWidth + Theme.popupPadding * 2)
    implicitHeight: terminalText.implicitHeight + Theme.popupPadding * 2
    color: "transparent"
    grabFocus: true

    anchor {
        item: root.anchorItem
        edges: Edges.Top | Edges.Right
        gravity: Edges.Top | Edges.Left
        margins.top: -6
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background
        border.color: Theme.subtle
        border.width: Theme.popupBorderWidth
        radius: Theme.radius

        Text {
            id: terminalText
            anchors.centerIn: parent
            text: root.ansiToHtml(BtopSession.snapshot)
            textFormat: Text.RichText
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: root.terminalFontSize
            renderType: Text.NativeRendering
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                BtopSession.open()
                root.visible = false
            }
        }
    }
}
