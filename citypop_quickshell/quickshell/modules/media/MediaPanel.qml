pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../../Singleton"
import "../../common"

Scope {
    id: root

    // ── Player state ──
    property int selectedPlayerIndex: -1
    property MprisPlayer _currentPlayer: null

    readonly property var allPlayers: Mpris.players.values
    readonly property MprisPlayer player: _currentPlayer

    function selectPlayer() {
        var players = allPlayers
        if (players.length === 0) { _currentPlayer = null; return }

        if (selectedPlayerIndex >= 0 && selectedPlayerIndex < players.length) {
            _currentPlayer = players[selectedPlayerIndex]
            return
        }

        // Auto-select: prefer playing player, else first
        for (var i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing) {
                selectedPlayerIndex = i
                _currentPlayer = players[i]
                return
            }
        }
        selectedPlayerIndex = 0
        _currentPlayer = players[0]
    }

    onAllPlayersChanged: selectPlayer()
    onSelectedPlayerIndexChanged: selectPlayer()
    Component.onCompleted: selectPlayer()

    on_CurrentPlayerChanged: trackedPosition = _currentPlayer?.position ?? 0

    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: {
        var artists = player?.trackArtists ?? []
        return artists.length > 0 ? artists[0] : ""
    }
    readonly property string album: player?.trackAlbum ?? ""
    readonly property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing
    readonly property bool hasMultiplePlayers: allPlayers.length > 1
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property string playerName: player?.identity ?? ""

    function formatTime(seconds) {
        var totalSec = Math.floor(seconds)
        var min = Math.floor(totalSec / 60)
        var sec = totalSec % 60
        return min + ":" + (sec < 10 ? "0" : "") + sec
    }

    // Polled position since MPRIS position doesn't emit continuous signals
    property real trackedPosition: player?.position ?? 0

    Timer {
        interval: 1000
        running: root.isPlaying && MediaState.visible
        repeat: true
        onTriggered: root.trackedPosition = root.player?.position ?? 0
    }

    // Sync on seek/track change
    Connections {
        target: root.player
        function onPositionChanged() { root.trackedPosition = root.player?.position ?? 0 }
    }

    function cyclePlayer() {
        var count = allPlayers.length
        if (count < 2) return
        selectedPlayerIndex = (selectedPlayerIndex + 1) % count
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            visible: MediaState.visible && MediaState.screen === modelData
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore

            MouseArea {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: Style.barHeight
                onClicked: MediaState.visible = false
            }

            // --- Dropdown Card ---
            Rectangle {
                id: card
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: Style.barHeight + Style.spaceMd
                width: 320
                height: cardContent.implicitHeight + Style.spaceXl * 2
                color: Style.bgSecondary
                radius: Style.radiusLg
                border.width: 1
                border.color: Style.bgTertiary

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: Style.spaceXl
                    spacing: Style.spaceLg

                    // ── Player switcher (only with multiple players) ──
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: playerRow.implicitHeight + Style.spaceSm * 2
                        radius: Style.radiusFull
                        color: playerHover.containsMouse ? Style.bgTertiary : "transparent"
                        visible: root.hasMultiplePlayers

                        Behavior on color { ColorAnimation { duration: Style.animFast } }

                        RowLayout {
                            id: playerRow
                            anchors.centerIn: parent
                            spacing: Style.spaceSm

                            MaterialIcon {
                                text: "music_note"
                                font.pixelSize: 14
                                color: Style.textDimmed
                            }

                            StyledText {
                                text: root.playerName
                                font.pixelSize: Style.fontSizeSm
                                color: Style.textDimmed
                            }

                            MaterialIcon {
                                text: "swap_horiz"
                                font.pixelSize: 14
                                color: Style.textDimmed
                            }
                        }

                        MouseArea {
                            id: playerHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cyclePlayer()
                        }
                    }

                    // ── Album Art ──
                    Rectangle {
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 140
                        Layout.alignment: Qt.AlignHCenter
                        radius: Style.radiusMd
                        color: Style.bgTertiary
                        clip: true
                        border.width: 1
                        border.color: Style.bgTertiary

                        Image {
                            id: albumArtImg
                            anchors.fill: parent
                            source: root.artUrl
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: true
                            visible: status === Image.Ready
                        }

                        // Fallback icon when no art
                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "album"
                            font.pixelSize: 56
                            color: Style.textDimmed
                            visible: albumArtImg.status !== Image.Ready
                            z: 0
                        }
                    }

                    // ── Track Info ──
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.spaceXs

                        StyledText {
                            text: root.title || "No track playing"
                            font.pixelSize: Style.fontSizeXl
                            font.bold: true
                            color: Style.textPrimary
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: root.artist
                            font.pixelSize: Style.fontSizeMd
                            color: Style.textSecondary
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            visible: root.artist !== ""
                        }

                        StyledText {
                            text: root.album
                            font.pixelSize: Style.fontSizeSm
                            color: Style.textDimmed
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            visible: root.album !== ""
                        }
                    }

                    // ── Seek Bar ──
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.spaceXs

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 16

                            property real pos: root.trackedPosition
                            property real len: root.player?.length ?? 0
                            property real fraction: len > 0 ? Math.min(1.0, Math.max(0, pos / len)) : 0

                            Rectangle {
                                id: seekTrack
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                height: seekArea.containsMouse || seekArea.isDragging ? 6 : 4
                                radius: height / 2
                                color: Style.bgTertiary

                                Behavior on height { NumberAnimation { duration: Style.animFast } }

                                Rectangle {
                                    width: parent.width * parent.parent.fraction
                                    height: parent.height
                                    radius: parent.radius
                                    color: Style.accentPink

                                    Behavior on width { NumberAnimation { duration: 200 } }
                                }

                                // Seek handle
                                Rectangle {
                                    x: Math.max(0, Math.min(parent.width - width, parent.width * parent.parent.fraction - width / 2))
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: seekArea.containsMouse || seekArea.isDragging ? 12 : 0
                                    height: width
                                    radius: width / 2
                                    color: Style.accentPink
                                    visible: width > 0

                                    Behavior on width { NumberAnimation { duration: Style.animFast } }
                                }
                            }

                            MouseArea {
                                id: seekArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: (root.player?.canSeek ?? false) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                property bool isDragging: false

                                onPressed: mouse => {
                                    if (!(root.player?.canSeek ?? false)) return
                                    isDragging = true
                                    seekTo(mouse.x)
                                }
                                onReleased: isDragging = false
                                onPositionChanged: mouse => {
                                    if (isDragging) seekTo(mouse.x)
                                }
                                onClicked: mouse => seekTo(mouse.x)

                                function seekTo(x) {
                                    if (!(root.player?.canSeek ?? false)) return
                                    var len = root.player?.length ?? 0
                                    if (len <= 0) return
                                    var frac = Math.max(0, Math.min(1, x / seekTrack.width))
                                    root.player.position = frac * len
                                }
                            }
                        }

                        // Time labels
                        RowLayout {
                            Layout.fillWidth: true

                            StyledText {
                                text: root.formatTime(root.trackedPosition)
                                font.pixelSize: 11
                                color: Style.textDimmed
                            }

                            Item { Layout.fillWidth: true }

                            StyledText {
                                text: root.formatTime(root.player?.length ?? 0)
                                font.pixelSize: 11
                                color: Style.textDimmed
                            }
                        }
                    }

                    // ── Playback Controls ──
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Style.spaceXl

                        // Previous
                        Rectangle {
                            implicitWidth: 36
                            implicitHeight: 36
                            radius: Style.radiusFull
                            color: prevCtrlHover.containsMouse ? Style.bgTertiary : "transparent"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "skip_previous"
                                font.pixelSize: 24
                                color: prevCtrlHover.containsMouse ? Style.textPrimary : Style.textSecondary
                            }

                            MouseArea {
                                id: prevCtrlHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.player?.previous()
                            }
                        }

                        // Play/Pause
                        Rectangle {
                            implicitWidth: 48
                            implicitHeight: 48
                            radius: Style.radiusFull
                            color: Style.accentPink

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: root.isPlaying ? "pause" : "play_arrow"
                                font.pixelSize: 32
                                color: Style.bgPrimary
                                fill: 1
                            }

                            MouseArea {
                                id: playPauseHover
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

                            scale: playPauseHover.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: Style.animFast } }
                        }

                        // Next
                        Rectangle {
                            implicitWidth: 36
                            implicitHeight: 36
                            radius: Style.radiusFull
                            color: nextCtrlHover.containsMouse ? Style.bgTertiary : "transparent"

                            Behavior on color { ColorAnimation { duration: Style.animFast } }

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "skip_next"
                                font.pixelSize: 24
                                color: nextCtrlHover.containsMouse ? Style.textPrimary : Style.textSecondary
                            }

                            MouseArea {
                                id: nextCtrlHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.player?.next()
                            }
                        }
                    }
                }
            }
        }
    }
}
