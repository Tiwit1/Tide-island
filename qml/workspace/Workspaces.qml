import Quickshell
import QtQuick
import Quickshell.Hyprland

Row {
    id: root
    spacing: 21
    property var labels: ["", "", "", "", "", "", "", "", ""]

    // Pass in the screen this bar belongs to from the parent (e.g. PanelWindow's `screen`)
    required property var screen

    // Resolve the Hyprland monitor object that matches this QtQuick screen
    property var monitor: Hyprland.monitorFor(root.screen)

    Repeater {
        model: 6

        Item {
            id: workspacesItem
            // Compare against THIS monitor's active workspace, not the global focused one
            property bool isActive: root.monitor?.activeWorkspace?.id === (index + 1)

            implicitWidth: Math.max(circle.implicitWidth, 22)
            implicitHeight: Math.max(circle.implicitHeight, 22)

            Rectangle {
                id: circle
                anchors.centerIn: parent
                height: Math.max(label.implicitWidth, label.implicitHeight) + 8
                width: height + 10
                radius: 10
                color: '#000000'
                opacity: workspacesItem.isActive ? 0.8 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            Text {
                id: label
                anchors.centerIn: parent
                text: root.labels[index]
                color: '#bdbdbd'
                font {
                    family: "JetBrainsMonoNL Nerd Font Mono"
                }
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + (index + 1))
            }
        }
    }
}