import Quickshell
import QtQuick
import Quickshell.Hyprland

Row {
    id: root
    spacing: 10

    // Pass in the screen this bar belongs to from the parent (e.g. PanelWindow's `screen`)
    required property var screen

    // Resolve the Hyprland monitor object that matches this QtQuick screen
    property var monitor: Hyprland.monitorFor(root.screen)

    // How many workspace dots to show
    property int workspaceCount: 6

    Repeater {
        model: root.workspaceCount

        Item {
            id: workspacesItem
            property bool isActive: root.monitor?.activeWorkspace?.id === (index + 1)

            implicitWidth: 16
            implicitHeight: 16

            WorkspaceIndicator {
                anchors.centerIn: parent
                width: 14
                height: 14
                active: workspacesItem.isActive
                inactiveColor: '#838383'
                activeColor: '#ffffff'
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + (index + 1))
            }
        }
    }
}