import QtQuick
import Quickshell
import "bar"
import "launcher"
import "notifications"
import "services"

ShellRoot {
    Component.onCompleted: BtopSession.ensureRunning()
    Bar {}
    Launcher {}
    Notifications {}
}
