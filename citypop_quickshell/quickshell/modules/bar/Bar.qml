import Quickshell
import QtQuick.Layouts
import "../../Singleton"
import "components"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            color: "#2b1b2f"

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 30

            Clock {
                anchors.centerIn: parent

                color: Style.textColor
                font.bold: true
                font.pixelSize: Style.fontSize
            }

            RowLayout {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 10
                // spacing: 6

                Volume {
                    showIcon: true
                }
            }
        }
    }
}
