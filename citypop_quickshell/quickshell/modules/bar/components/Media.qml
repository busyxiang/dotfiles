pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../../Singleton"
import "../../../common"

RowLayout {
    id: root
    property real sf: 1.0

    spacing: Math.round(Style.spaceMd * sf)
    visible: player !== null

    readonly property MprisPlayer player: {
        var players = Mpris.players.values
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

    StyledText {
        text: {
            if (root.artist && root.title)
                return root.artist + " — " + root.title
            return root.title || ""
        }
        color: Style.textSecondary
        font.pixelSize: Math.round(Style.fontSizeSm * root.sf)
        elide: Text.ElideRight
        Layout.preferredWidth: Math.round(200 * root.sf)
    }
}
