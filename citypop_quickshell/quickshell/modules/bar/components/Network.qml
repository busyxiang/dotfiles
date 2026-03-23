pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../network"
import "../../../Singleton"
import "../../../common"

Item {
    id: root
    property real sf: 1.0
    property var screen: null

    implicitWidth: contentRow.implicitWidth
    implicitHeight: contentRow.implicitHeight

    RowLayout {
        id: contentRow
        spacing: Math.round(Style.spaceSm * root.sf)

        // Show icon only for non-wifi or disconnected
        MaterialIcon {
            id: icon
            text: NetworkManager.iconName
            font.pixelSize: Math.round(18 * root.sf)
            color: NetworkManager.panelVisible ? Style.accentMagenta
                 : NetworkManager.connected ? Style.accentPink
                 : Style.textDimmed
            fill: 0
            visible: !NetworkManager.isWifi || !NetworkManager.connected

            Behavior on color {
                ColorAnimation { duration: Style.animNormal }
            }
        }

        // Signal strength bars (replaces icon for wifi)
        Row {
            spacing: Math.round(2 * root.sf)
            visible: NetworkManager.isWifi && NetworkManager.connected
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: 4

                Rectangle {
                    required property int index

                    property bool isLit: NetworkManager.signalStrength > index * 25

                    width: Math.round(3 * root.sf)
                    height: Math.round((6 + index * 3) * root.sf)
                    radius: 1
                    anchors.bottom: parent.bottom
                    color: isLit ? (NetworkManager.panelVisible ? Style.accentMagenta : Style.accentPink)
                                 : Style.bgTertiary

                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                }
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onContainsMouseChanged: {
            if (containsMouse && NetworkManager.connected && !NetworkManager.panelVisible) {
                var globalPos = root.mapToItem(null, root.width / 2, 0)
                NetworkManager.tooltipX = globalPos.x
                NetworkManager.tooltipScreen = root.screen
                NetworkManager.tooltipVisible = true
            } else {
                NetworkManager.tooltipVisible = false
            }
        }

        onClicked: {
            NetworkManager.tooltipVisible = false
            NetworkManager.panelScreen = root.screen
            NetworkManager.togglePanel()
        }
    }
}
