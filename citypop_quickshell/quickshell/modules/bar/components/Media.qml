pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../../Singleton"
import "../../../common"
import "../../media"

Item {
    id: root
    property real sf: 1.0
    property var screen: null

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight
    visible: player !== null

    readonly property var allPlayers: Mpris.players.values

    readonly property MprisPlayer player: {
        var players = root.allPlayers
        if (players.length === 0) return null
        for (var i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i]
        }
        return players.length > 0 ? players[0] : null
    }

    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: {
        var artists = player?.trackArtists ?? []
        if (typeof artists === "string") return artists
        return artists.length > 0 ? artists.join(", ") : ""
    }
    readonly property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing


    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Math.round(Style.spaceMd * root.sf)

        // --- Playback controls ---
        MaterialIcon {
            text: "skip_previous"
            font.pixelSize: Math.round(16 * root.sf)
            color: Style.textSecondary

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.player?.previous()
            }
        }

        // Vinyl disc / play-pause button
        Item {
            id: discContainer
            implicitWidth: Math.round(20 * root.sf)
            implicitHeight: Math.round(20 * root.sf)

            // Disc (visible when playing)
            Rectangle {
                id: disc
                anchors.fill: parent
                radius: width / 2
                color: Style.bgTertiary
                border.width: 1.5
                border.color: Style.accentPink
                visible: root.isPlaying
                opacity: discHover.containsMouse ? 0.4 : 1

                Behavior on opacity { NumberAnimation { duration: Style.animFast } }

                // Groove ring (spins to show rotation)
                Rectangle {
                    id: grooveRing
                    anchors.centerIn: parent
                    width: parent.width * 0.65
                    height: parent.height * 0.65
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Style.accentPink
                    opacity: 0.3

                    // Small notch to make spinning visible
                    Rectangle {
                        width: 3
                        height: 3
                        radius: 1.5
                        color: Style.accentPink
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: -1
                    }

                    RotationAnimation on rotation {
                        running: root.isPlaying
                        from: 0
                        to: 360
                        duration: 3000
                        loops: Animation.Infinite
                    }
                }

                // Center hole
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.round(4 * root.sf)
                    height: Math.round(4 * root.sf)
                    radius: width / 2
                    color: Style.accentPink
                }
            }

            // Pause icon on hover (over disc)
            MaterialIcon {
                anchors.centerIn: parent
                text: "pause"
                font.pixelSize: Math.round(16 * root.sf)
                color: Style.accentPink
                fill: 1
                visible: root.isPlaying && discHover.containsMouse
            }

            // Play icon (when paused)
            MaterialIcon {
                anchors.centerIn: parent
                text: "play_arrow"
                font.pixelSize: Math.round(20 * root.sf)
                color: Style.accentPink
                fill: 1
                visible: !root.isPlaying
            }

            MouseArea {
                id: discHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.isPlaying)
                        root.player?.pause()
                    else
                        root.player?.play()
                }
            }
        }

        MaterialIcon {
            text: "skip_next"
            font.pixelSize: Math.round(16 * root.sf)
            color: Style.textSecondary

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.player?.next()
            }
        }

        // --- Marquee track text (click to open panel) ---
        Item {
            id: marqueeContainer
            Layout.preferredWidth: Math.round(200 * root.sf)
            Layout.preferredHeight: marqueeText.implicitHeight
            clip: true

            property string displayText: {
                if (root.artist && root.title)
                    return root.artist + " \u2014 " + root.title
                return root.title || ""
            }

            property bool needsScroll: marqueeText.implicitWidth > marqueeContainer.width

            StyledText {
                id: marqueeText
                text: marqueeContainer.displayText
                color: Style.textSecondary
                font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
                y: 0
                x: 0

                SequentialAnimation on x {
                    id: marqueeAnim
                    running: marqueeContainer.needsScroll
                    loops: Animation.Infinite

                    PauseAnimation { duration: 2000 }

                    NumberAnimation {
                        from: 0
                        to: -(marqueeText.implicitWidth - marqueeContainer.width + Math.round(20 * root.sf))
                        duration: Math.max(3000, (marqueeText.implicitWidth - marqueeContainer.width) * 20)
                        easing.type: Easing.Linear
                    }

                    PauseAnimation { duration: 1500 }

                    NumberAnimation {
                        to: 0
                        duration: 0
                    }
                }
            }

            Connections {
                target: marqueeContainer
                function onDisplayTextChanged() {
                    marqueeText.x = 0
                    marqueeAnim.restart()
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var wasOpen = MediaState.visible
                    PanelManager.closeAll()
                    if (!wasOpen) {
                        MediaState.screen = root.screen
                        MediaState.visible = true
                    }
                }
            }
        }
    }

}
