pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Mpris
import "../../Singleton"
import "../../common"

Scope {
    id: root

    // ── Auth state (shared across surfaces) ──
    property int _attempts: 0
    property int _failures: 0
    property bool _authActive: false
    property string _authMessage: ""
    property bool _authError: false
    property int _failSignal: 0
    property bool _unlocking: false

    // ── Caps lock ──
    property bool _capsLock: false

    // ── Now playing ──
    readonly property MprisPlayer _activePlayer: {
        var players = Mpris.players.values
        for (var i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i]
        }
        return players.length > 0 ? players[0] : null
    }

    readonly property bool _hasMusic: {
        if (!_activePlayer) return false
        if (_activePlayer.playbackState !== MprisPlaybackState.Playing) return false
        return (_activePlayer.trackTitle ?? "") !== ""
    }

    readonly property string _trackTitle: _activePlayer?.trackTitle ?? ""

    readonly property string _trackArtist: {
        if (!_activePlayer) return ""
        var artists = _activePlayer.trackArtists
        if (typeof artists === "string") return artists
        if (artists && artists.length > 0) return artists[0]
        return ""
    }

    // ── Playback progress ──
    property real _playbackProgress: 0

    // ── Greeting ──
    property string _user: ""

    Process {
        id: userProc
        command: ["sh", "-c", "echo $USER"]
        running: true
        stdout: SplitParser {
            onRead: data => { root._user = data.trim() }
        }
    }

    // Re-evaluated every minute via _hours dependency
    readonly property string _greeting: {
        void root._hours  // force re-eval when clock updates
        var hour = new Date().getHours()
        var name = root._user || "there"
        if (hour < 12) return "Good morning, " + name
        if (hour < 17) return "Good afternoon, " + name
        return "Good evening, " + name
    }

    // ── Clock (split for pulsing colon) ──
    property string _hours: ""
    property string _minutes: ""
    property string _ampm: ""
    property string _dateStr: ""

    property real _colonOpacity: 1.0
    SequentialAnimation {
        running: LockState.locked
        loops: Animation.Infinite
        NumberAnimation {
            target: root; property: "_colonOpacity"
            from: 1.0; to: 0.3; duration: 500
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root; property: "_colonOpacity"
            from: 0.3; to: 1.0; duration: 500
            easing.type: Easing.InOutSine
        }
    }

    Timer {
        id: clockTimer
        interval: 1000
        running: LockState.locked
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            var h = now.getHours()
            root._ampm = h >= 12 ? "PM" : "AM"
            h = h % 12
            if (h === 0) h = 12
            root._hours = h.toString()
            root._minutes = now.getMinutes().toString().padStart(2, "0")

            var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            var months = ["January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]
            root._dateStr = days[now.getDay()] + ", " + months[now.getMonth()] + " " + now.getDate()

            if (root._activePlayer && root._activePlayer.length > 0) {
                root._playbackProgress = Math.max(0, Math.min(1, root._activePlayer.position / root._activePlayer.length))
            } else {
                root._playbackProgress = 0
            }
        }
    }

    // ── PAM ──
    PamContext {
        id: pam
        config: "quickshell"

        onPamMessage: {
            if (pam.messageIsError) {
                root._authMessage = pam.message
                root._authError = true
            }
        }

        onCompleted: (result) => {
            if (result === PamResult.Success) {
                root._authActive = false
                root._authMessage = ""
                root._unlocking = true
                unlockTimer.start()
            } else {
                root._failures++
                root._authActive = false
                root._authMessage = "Authentication failed"
                root._authError = true
                root._failSignal++
                restartPamTimer.start()
            }
        }

        onError: (error) => {
            root._authActive = false
            root._authMessage = "PAM error"
            root._authError = true
            restartPamTimer.start()
        }
    }

    Timer {
        id: restartPamTimer
        interval: 500
        onTriggered: { if (LockState.locked) pam.start() }
    }

    Timer {
        id: unlockTimer
        interval: 400
        onTriggered: {
            root._attempts = 0
            root._failures = 0
            root._unlocking = false
            LockState.locked = false
            LockState.screen = null
        }
    }

    function submitPassword(password: string): void {
        if (password.length === 0 || _authActive || !pam.responseRequired) return
        _authActive = true
        _attempts++
        _authMessage = ""
        _authError = false
        pam.respond(password)
    }

    // ── Caps lock polling ──
    Process {
        id: capsProc
        command: ["sh", "-c", "cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | head -1"]
        stdout: SplitParser {
            onRead: data => { root._capsLock = data.trim() === "1" }
        }
    }

    Timer {
        interval: 500
        running: LockState.locked
        repeat: true
        triggeredOnStart: true
        onTriggered: capsProc.running = true
    }

    // ── Session lock ──
    Loader {
        id: lockLoader
        active: LockState.locked

        sourceComponent: WlSessionLock {
            id: sessionLock
            locked: true

            onSecureChanged: {
                if (secure) {
                    root._authMessage = ""
                    root._authError = false
                    root._failSignal = 0
                    pam.start()
                }
            }

            Component.onDestruction: locked = false

            surface: Component {
                WlSessionLockSurface {
                    id: lockSurface
                    color: "#0d0520"

                    readonly property real sf: lockSurface.height / 1080
                    readonly property bool isPrimary: lockSurface.screen === LockState.screen

                    // ── Wallpaper background ──
                    Image {
                        anchors.fill: parent
                        source: "file:///home/ray/Pictures/citypop_wallpaper.jpg"
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    // Dark overlay with purple tint
                    Rectangle {
                        anchors.fill: parent
                        color: Style.bgPrimary
                        opacity: root._unlocking ? 0 : 0.78
                        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InCubic } }
                    }

                    // Vignette edges
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#60000000" }
                            GradientStop { position: 0.15; color: "transparent" }
                            GradientStop { position: 0.85; color: "transparent" }
                            GradientStop { position: 1.0; color: "#60000000" }
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#50000000" }
                            GradientStop { position: 0.15; color: "transparent" }
                            GradientStop { position: 0.85; color: "transparent" }
                            GradientStop { position: 1.0; color: "#50000000" }
                        }
                    }

                    // ── Rain particle overlay ──
                    Canvas {
                        id: rainCanvas
                        anchors.fill: parent
                        opacity: root._unlocking ? 0 : 0.35
                        Behavior on opacity { NumberAnimation { duration: 350 } }

                        property var drops: []
                        property int dropCount: 80
                        property bool _initialized: false

                        function initDrops() {
                            if (_initialized || width <= 0 || height <= 0) return
                            _initialized = true
                            var d = []
                            for (var i = 0; i < dropCount; i++) {
                                d.push({
                                    x: Math.random() * width,
                                    y: Math.random() * height,
                                    len: 8 + Math.random() * 20,
                                    speed: 2 + Math.random() * 4,
                                    opacity: 0.1 + Math.random() * 0.4
                                })
                            }
                            drops = d
                        }

                        onWidthChanged: initDrops()
                        onHeightChanged: initDrops()

                        Timer {
                            running: LockState.locked && !root._unlocking && rainCanvas._initialized
                            interval: 33  // ~30fps
                            repeat: true
                            onTriggered: {
                                var d = rainCanvas.drops
                                var w = rainCanvas.width
                                var h = rainCanvas.height
                                for (var i = 0; i < d.length; i++) {
                                    d[i].y += d[i].speed
                                    d[i].x += d[i].speed * 0.15  // slight wind angle
                                    if (d[i].y > h + d[i].len) {
                                        d[i].y = -d[i].len
                                        d[i].x = Math.random() * w
                                    }
                                    if (d[i].x > w) d[i].x = 0
                                }
                                rainCanvas.requestPaint()
                            }
                        }

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            var d = drops
                            for (var i = 0; i < d.length; i++) {
                                ctx.strokeStyle = "rgba(255, 105, 180, " + d[i].opacity + ")"
                                ctx.lineWidth = 1
                                ctx.beginPath()
                                ctx.moveTo(d[i].x, d[i].y)
                                ctx.lineTo(d[i].x + d[i].len * 0.15, d[i].y + d[i].len)
                                ctx.stroke()
                            }
                        }
                    }

                    // ── Ambient pink glow behind card (primary only) ──
                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.round(600 * lockSurface.sf)
                        height: Math.round(500 * lockSurface.sf)
                        radius: width / 2
                        color: Style.accentPink
                        opacity: 0.04
                        visible: lockSurface.isPrimary
                    }

                    // ── Secondary screen: just clock ──
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Math.round(4 * lockSurface.sf)
                        visible: !lockSurface.isPrimary

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root._hours + ":" + root._minutes + " " + root._ampm
                            font.pixelSize: Math.round(48 * lockSurface.sf)
                            font.weight: Font.Bold
                            color: Style.accentPink
                            opacity: 0.6
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root._dateStr
                            font.pixelSize: Math.round(16 * lockSurface.sf)
                            color: Style.textSecondary
                            opacity: 0.4
                        }
                    }

                    // ── Center content (primary only) ──
                    Item {
                        visible: lockSurface.isPrimary
                        anchors.centerIn: parent
                        width: Math.round(460 * lockSurface.sf)
                        height: outerCol.implicitHeight

                        Component.onCompleted: {
                            if (lockSurface.isPrimary) passwordInput.forceActiveFocus()
                        }

                        opacity: root._unlocking ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InCubic } }

                        transform: Translate {
                            y: root._unlocking ? 20 : 0
                            Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.InCubic } }
                        }

                        ColumnLayout {
                            id: outerCol
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            spacing: 0

                            // ── Greeting (above card) ──
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: root._greeting
                                font.pixelSize: Math.round(28 * lockSurface.sf)
                                color: Style.textPrimary
                                opacity: greetingFade.running ? greetingFade._val : 0.85
                                Layout.bottomMargin: Math.round(20 * lockSurface.sf)

                                NumberAnimation {
                                    id: greetingFade
                                    property real _val: 0
                                    target: greetingFade; property: "_val"
                                    from: 0; to: 0.85; duration: 600
                                    easing.type: Easing.OutCubic
                                    running: true
                                }
                            }

                            // ── Main card ──
                            Rectangle {
                                id: lockCard
                                Layout.fillWidth: true
                                implicitHeight: cardCol.implicitHeight + Math.round(48 * lockSurface.sf)
                                color: Style.bgSecondary
                                radius: Style.radiusLg
                                border.width: 1
                                border.color: Style.bgTertiary

                                // Fade + slide in
                                opacity: cardFade._val
                                transform: Translate { y: cardSlide._val }

                                NumberAnimation {
                                    id: cardFade
                                    property real _val: 0
                                    target: cardFade; property: "_val"
                                    from: 0; to: 1; duration: 500
                                    easing.type: Easing.OutCubic
                                    running: true
                                }
                                NumberAnimation {
                                    id: cardSlide
                                    property real _val: 12
                                    target: cardSlide; property: "_val"
                                    from: 12; to: 0; duration: 500
                                    easing.type: Easing.OutCubic
                                    running: true
                                }

                                // Outer neon glow
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    radius: parent.radius + 3
                                    color: "transparent"
                                    border.width: 1
                                    border.color: Style.pinkBorder
                                    opacity: 0.4
                                }

                                NeonStrip {}

                                ColumnLayout {
                                    id: cardCol
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.topMargin: Math.round(28 * lockSurface.sf)
                                    anchors.leftMargin: Math.round(24 * lockSurface.sf)
                                    anchors.rightMargin: Math.round(24 * lockSurface.sf)
                                    spacing: 0

                                    // ── Clock row with pulsing colon ──
                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 0

                                        StyledText {
                                            text: root._hours
                                            font.pixelSize: Math.round(64 * lockSurface.sf)
                                            font.weight: Font.Bold
                                            color: Style.accentPink
                                        }

                                        StyledText {
                                            text: ":"
                                            font.pixelSize: Math.round(64 * lockSurface.sf)
                                            font.weight: Font.Bold
                                            color: Style.accentPink
                                            opacity: root._colonOpacity
                                        }

                                        StyledText {
                                            text: root._minutes
                                            font.pixelSize: Math.round(64 * lockSurface.sf)
                                            font.weight: Font.Bold
                                            color: Style.accentPink
                                        }

                                        StyledText {
                                            text: " " + root._ampm
                                            font.pixelSize: Math.round(22 * lockSurface.sf)
                                            color: Style.accentPink
                                            opacity: 0.7
                                            Layout.alignment: Qt.AlignBottom
                                            Layout.bottomMargin: Math.round(10 * lockSurface.sf)
                                        }
                                    }

                                    // Date
                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: root._dateStr
                                        font.pixelSize: Math.round(16 * lockSurface.sf)
                                        color: Style.textSecondary
                                        opacity: 0.7
                                        Layout.bottomMargin: Math.round(20 * lockSurface.sf)
                                    }

                                    // ── Neon divider ──
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: Style.accentPink
                                        opacity: 0.2
                                        Layout.bottomMargin: Math.round(20 * lockSurface.sf)
                                    }

                                    // ── Password input ──
                                    Item {
                                        id: inputWrapper
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: Math.round(320 * lockSurface.sf)
                                        Layout.preferredHeight: Math.round(48 * lockSurface.sf)
                                        Layout.bottomMargin: Math.round(12 * lockSurface.sf)

                                        property real _shakeOffset: 0
                                        transform: Translate { x: inputWrapper._shakeOffset }

                                        SequentialAnimation {
                                            id: shakeAnim
                                            NumberAnimation { target: inputWrapper; property: "_shakeOffset"; to: -12; duration: 50; easing.type: Easing.InOutQuad }
                                            NumberAnimation { target: inputWrapper; property: "_shakeOffset"; to: 12; duration: 50; easing.type: Easing.InOutQuad }
                                            NumberAnimation { target: inputWrapper; property: "_shakeOffset"; to: -8; duration: 50; easing.type: Easing.InOutQuad }
                                            NumberAnimation { target: inputWrapper; property: "_shakeOffset"; to: 8; duration: 50; easing.type: Easing.InOutQuad }
                                            NumberAnimation { target: inputWrapper; property: "_shakeOffset"; to: -4; duration: 50; easing.type: Easing.InOutQuad }
                                            NumberAnimation { target: inputWrapper; property: "_shakeOffset"; to: 0; duration: 50; easing.type: Easing.InOutQuad }
                                        }

                                        Connections {
                                            target: root
                                            function on_FailSignalChanged() {
                                                if (root._failSignal > 0) {
                                                    passwordInput.text = ""
                                                    shakeAnim.start()
                                                }
                                            }
                                        }

                                        Rectangle {
                                            id: inputBg
                                            anchors.fill: parent
                                            radius: Style.radiusFull
                                            color: Style.bgTertiary
                                            border.width: 2
                                            border.color: passwordInput.activeFocus ? Style.accentPink : Style.pinkBorder

                                            Behavior on border.color { ColorAnimation { duration: Style.animNormal } }

                                            Rectangle {
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                radius: parent.radius + 4
                                                color: "transparent"
                                                border.width: 2
                                                border.color: Style.accentPink
                                                opacity: passwordInput.activeFocus ? 0.25 : 0
                                                Behavior on opacity { NumberAnimation { duration: Style.animNormal } }
                                            }

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: Math.round(18 * lockSurface.sf)
                                                anchors.rightMargin: Math.round(18 * lockSurface.sf)
                                                spacing: Math.round(10 * lockSurface.sf)

                                                MaterialIcon {
                                                    text: "lock"
                                                    font.pixelSize: Math.round(18 * lockSurface.sf)
                                                    color: passwordInput.activeFocus ? Style.accentPink : Style.textDimmed
                                                    fill: 1
                                                    Behavior on color { ColorAnimation { duration: Style.animFast } }
                                                }

                                                TextInput {
                                                    id: passwordInput
                                                    Layout.fillWidth: true
                                                    echoMode: TextInput.Password
                                                    passwordCharacter: "\u25CF"
                                                    font.family: Style.fontFamily
                                                    font.pixelSize: Math.round(16 * lockSurface.sf)
                                                    color: Style.textPrimary
                                                    selectionColor: Style.accentPink
                                                    selectedTextColor: Style.bgPrimary
                                                    clip: true
                                                    focus: true

                                                    Keys.onReturnPressed: root.submitPassword(passwordInput.text)
                                                    Keys.onEscapePressed: passwordInput.text = ""
                                                }

                                                MaterialIcon {
                                                    text: "progress_activity"
                                                    font.pixelSize: Math.round(16 * lockSurface.sf)
                                                    color: Style.accentPink
                                                    fill: 0
                                                    visible: root._authActive

                                                    RotationAnimation on rotation {
                                                        from: 0; to: 360
                                                        duration: 1200
                                                        loops: Animation.Infinite
                                                        running: root._authActive
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // ── Caps lock warning ──
                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredHeight: Math.round(22 * lockSurface.sf)
                                        spacing: Math.round(6 * lockSurface.sf)
                                        visible: root._capsLock

                                        MaterialIcon {
                                            text: "warning"
                                            font.pixelSize: Math.round(14 * lockSurface.sf)
                                            color: Style.accentAmber
                                            fill: 1
                                        }

                                        StyledText {
                                            text: "CAPS LOCK ON"
                                            font.pixelSize: Math.round(13 * lockSurface.sf)
                                            font.weight: Font.DemiBold
                                            color: Style.accentAmber

                                            SequentialAnimation on opacity {
                                                running: root._capsLock
                                                loops: Animation.Infinite
                                                NumberAnimation { to: 0.4; duration: 800; easing.type: Easing.InOutQuad }
                                                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                                            }
                                        }
                                    }

                                    // ── Auth message ──
                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.topMargin: root._authMessage !== "" ? Math.round(4 * lockSurface.sf) : 0
                                        Layout.preferredHeight: root._authMessage !== "" ? implicitHeight : 0
                                        text: root._authMessage
                                        visible: root._authMessage !== ""
                                        font.pixelSize: Math.round(13 * lockSurface.sf)
                                        color: root._authError ? Style.colorUrgent : Style.textSecondary
                                    }

                                    // ── Attempt counter ──
                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.topMargin: root._attempts > 0 ? Math.round(4 * lockSurface.sf) : 0
                                        Layout.preferredHeight: root._attempts > 0 ? implicitHeight : 0
                                        text: "Attempts: " + root._attempts + "  |  Failed: " + root._failures
                                        visible: root._attempts > 0
                                        font.pixelSize: Math.round(12 * lockSurface.sf)
                                        color: Style.textDimmed
                                    }

                                    // ── Now playing section ──
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: Style.accentPink
                                        opacity: 0.2
                                        Layout.topMargin: Math.round(16 * lockSurface.sf)
                                        Layout.bottomMargin: Math.round(16 * lockSurface.sf)
                                        visible: root._hasMusic
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Math.round(10 * lockSurface.sf)
                                        visible: root._hasMusic

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            spacing: Math.round(8 * lockSurface.sf)

                                            MaterialIcon {
                                                text: "music_note"
                                                font.pixelSize: Math.round(16 * lockSurface.sf)
                                                color: Style.accentPink
                                                fill: 1
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            StyledText {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignVCenter
                                                text: root._trackArtist ? (root._trackArtist + " \u2014 " + root._trackTitle) : root._trackTitle
                                                font.pixelSize: Math.round(13 * lockSurface.sf)
                                                color: Style.textSecondary
                                                elide: Text.ElideRight
                                            }
                                        }

                                        VUMeter {
                                            Layout.fillWidth: true
                                            segments: 16
                                            value: root._playbackProgress
                                            muted: false
                                            segmentHeight: Math.round(4 * lockSurface.sf)
                                            segmentSpacing: Math.round(2 * lockSurface.sf)
                                            baseColor: Style.accentPink
                                            warnAt: 2.0
                                            critAt: 2.0
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Click anywhere to focus password input (primary only)
                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        visible: lockSurface.isPrimary
                        onClicked: passwordInput.forceActiveFocus()
                    }
                }
            }
        }
    }
}
