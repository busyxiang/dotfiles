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
        return artists.length > 0 ? artists[0] : ""
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

        MaterialIcon {
            text: root.isPlaying ? "pause" : "play_arrow"
            font.pixelSize: Math.round(20 * root.sf)
            color: Style.accentPink
            fill: 1

            MouseArea {
                anchors.fill: parent
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
                    MediaState.screen = root.screen
                    MediaState.visible = !MediaState.visible
                }
            }
        }
    }
}
