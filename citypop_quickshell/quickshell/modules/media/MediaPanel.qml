pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
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

            // ── Neon glow (behind card) ──
            Rectangle {
                id: glowRect
                anchors.fill: card
                anchors.margins: -3
                radius: Style.radiusLg + 3
                color: Style.accentPink
                opacity: root.isPlaying ? 0.3 : 0

                Behavior on opacity { NumberAnimation { duration: Style.animNormal } }
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
                border.color: root.isPlaying ? Qt.rgba(1, 0.41, 0.71, 0.3) : Style.bgTertiary

                Behavior on border.color { ColorAnimation { duration: Style.animNormal } }

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

                    // ── Vinyl Record Album Art ──
                    Item {
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 160
                        Layout.alignment: Qt.AlignHCenter

                        // Vinyl disc — ClippingRectangle for proper circular clip
                        ClippingRectangle {
                            id: vinylClip
                            anchors.fill: parent
                            radius: Infinity
                            color: "#1a1a1a"

                            // Rotating content
                            Item {
                                id: vinylDisc
                                anchors.fill: parent

                                RotationAnimation on rotation {
                                    running: root.isPlaying && MediaState.visible
                                    from: 0
                                    to: 360
                                    duration: 5000
                                    loops: Animation.Infinite
                                }

                                // Groove rings
                                Repeater {
                                    model: 3

                                    Rectangle {
                                        required property int index
                                        anchors.centerIn: parent
                                        width: parent.width - index * 8 - 4
                                        height: parent.height - index * 8 - 4
                                        radius: width / 2
                                        color: "transparent"
                                        border.width: 1
                                        border.color: Qt.rgba(1, 1, 1, 0.06)
                                    }
                                }

                                // Spin notch
                                Rectangle {
                                    width: 4
                                    height: 4
                                    radius: 2
                                    color: Style.accentPink
                                    opacity: 0.6
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.topMargin: 4
                                }

                                // Album art (fills disc)
                                Image {
                                    id: albumArtImg
                                    anchors.centerIn: parent
                                    width: parent.width - 12
                                    height: parent.height - 12
                                    source: root.artUrl
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    asynchronous: true
                                    visible: status === Image.Ready
                                }

                                // Fallback icon
                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "album"
                                    font.pixelSize: 56
                                    color: Style.textDimmed
                                    visible: albumArtImg.status !== Image.Ready
                                }

                                // Center hole
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: "#1a1a1a"
                                }
                            }
                        }

                        // Outer ring accent
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: 1.5
                            border.color: root.isPlaying ? Style.accentPink : Style.bgTertiary
                            opacity: root.isPlaying ? 0.5 : 0.3

                            Behavior on border.color { ColorAnimation { duration: Style.animNormal } }
                            Behavior on opacity { NumberAnimation { duration: Style.animNormal } }
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

                    // ── VU Meter Seek Bar ──
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.spaceXs

                        Item {
                            id: seekItem
                            Layout.fillWidth: true
                            implicitHeight: 20

                            property real pos: root.trackedPosition
                            property real len: root.player?.length ?? 0
                            property real fraction: len > 0 ? Math.min(1.0, Math.max(0, pos / len)) : 0

                            // VU meter segments
                            Row {
                                id: vuMeter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                property int totalSegments: 20
                                property int litSegments: Math.round(seekItem.fraction * totalSegments)

                                Repeater {
                                    model: vuMeter.totalSegments

                                    Rectangle {
                                        required property int index
                                        property bool isLit: index < vuMeter.litSegments

                                        width: (vuMeter.width - (vuMeter.totalSegments - 1) * vuMeter.spacing) / vuMeter.totalSegments
                                        height: seekArea.containsMouse || seekArea.isDragging ? 10 : 8
                                        radius: 1
                                        color: isLit ? Style.accentPink : Style.bgTertiary

                                        Behavior on color { ColorAnimation { duration: 60 } }
                                        Behavior on height { NumberAnimation { duration: Style.animFast } }
                                    }
                                }
                            }

                            // Seek handle
                            Rectangle {
                                x: Math.max(0, Math.min(seekItem.width - width, seekItem.width * seekItem.fraction - width / 2))
                                anchors.verticalCenter: parent.verticalCenter
                                width: seekArea.containsMouse || seekArea.isDragging ? 14 : 0
                                height: width
                                radius: width / 2
                                color: Style.accentPink
                                visible: width > 0
                                z: 1

                                Behavior on width { NumberAnimation { duration: Style.animFast } }
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
                                    var frac = Math.max(0, Math.min(1, x / seekItem.width))
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
