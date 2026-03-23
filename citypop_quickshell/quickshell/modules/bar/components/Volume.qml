pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

import "../../../Singleton"
import "../../../common"
import "../../volume"

Item {
    id: root

    property real sf: 1.0
    property bool showIcon: false
    property var screen: null

    readonly property real volume: Pipewire.defaultAudioSink?.audio.volume ?? 0
    readonly property bool muted: Pipewire.defaultAudioSink?.audio.muted ?? false

    readonly property string iconName: {
        if (muted) return "volume_off"
        if (volume > 0.66) return "volume_up"
        if (volume > 0.33) return "volume_down"
        if (volume > 0.0) return "volume_down"
        return "volume_off"
    }

    function getVolumeColor() {
        if (muted) return Style.textDimmed
        var pct = Math.round(volume * 100)
        if (pct > 130) return Style.colorUrgent
        if (pct > 100) return Style.accentAmber
        return Style.accentPink
    }

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Math.round(Style.spaceMd * root.sf)

        MaterialIcon {
            id: muteIcon
            text: root.iconName
            font.pixelSize: Math.round(20 * root.sf)
            color: root.getVolumeColor()
            fill: 0

            Behavior on color {
                ColorAnimation { duration: Style.animFast }
            }
        }

        StyledText {
            text: Math.round(root.volume * 100) + "%"
            font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
            color: root.muted ? Style.textDimmed
                 : Math.round(root.volume * 100) > 130 ? Style.colorUrgent
                 : Math.round(root.volume * 100) > 100 ? Style.accentAmber
                 : Style.textSecondary

            Behavior on color { ColorAnimation { duration: Style.animFast } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: {
            VolumeState.screen = root.screen
            VolumeState.visible = !VolumeState.visible
        }
        onWheel: wheel => {
            if (Pipewire.defaultAudioSink?.audio) {
                var delta = wheel.angleDelta.y / 120
                var newVolume = Math.max(0.0, Math.min(1.5, Pipewire.defaultAudioSink.audio.volume + delta * 0.05))
                Pipewire.defaultAudioSink.audio.volume = newVolume
            }
        }
    }
}
