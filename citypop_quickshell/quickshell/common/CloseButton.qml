import QtQuick
import "../Singleton"

// Reusable panel close button — 28x28 circle with hover effect.
Rectangle {
    id: btn

    signal clicked()

    implicitWidth: 28
    implicitHeight: 28
    radius: Style.radiusFull
    color: hover.containsMouse ? Style.bgTertiary : "transparent"

    Behavior on color { ColorAnimation { duration: Style.animFast } }

    MaterialIcon {
        anchors.centerIn: parent
        text: "close"
        font.pixelSize: 16
        color: hover.containsMouse ? Style.textPrimary : Style.textDimmed
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
