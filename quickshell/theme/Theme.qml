pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property color background: "#000000"
    readonly property color foreground: "#ffffff"
    readonly property color accent: "#6e98eb"
    readonly property color inactive: "#888888"
    readonly property color subtle: "#474747"
    readonly property color urgent: "#f07178"
    readonly property color disk: "#c792ea"
    readonly property color memory: "#82aaff"
    readonly property color cpu: "#ffcb6b"
    readonly property color network: "#c3e88d"

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property string awesomeFontFamily: "Font Awesome 6 Sharp"
    readonly property string brandFontFamily: "Font Awesome 6 Brands"
    readonly property string iconFontFamily: awesomeFontFamily
    readonly property int fontSize: 22
    readonly property int popupFontSize: fontSize
    readonly property int popupSmallFontSize: fontSize
    readonly property int popupTitleFontSize: fontSize

    readonly property int barHeight: 48
    readonly property int modulePadding: 10
    readonly property int moduleSpacing: 8
    readonly property int workspacePadding: 8
    readonly property int workspaceMargin: 0
    readonly property int popupWidth: 560
    readonly property int popupPadding: 24
    readonly property int popupSpacing: 18
    readonly property int popupBorderWidth: 2
    readonly property int radius: 0
}
