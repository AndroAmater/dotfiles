import QtQuick
import Quickshell
import "bar"
import "services"

ShellRoot {
    Component.onCompleted: BtopSession.ensureRunning()
    Bar {}
}
