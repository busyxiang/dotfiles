pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../../Singleton"
import "../../common"

Scope {
    id: root

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    // ── Output state ──
    readonly property real outVol: Pipewire.defaultAudioSink?.audio.volume ?? 0
    readonly property bool outMuted: Pipewire.defaultAudioSink?.audio.muted ?? false
    readonly property string outName: Pipewire.defaultAudioSink?.description ?? "No output"
    readonly property bool outOverdrive: outVol > 1.0
    readonly property string outIcon: {
        if (outMuted) return "volume_off"
        if (outVol > 0.66) return "volume_up"
        if (outVol > 0.33) return "volume_down"
        return outVol > 0 ? "volume_down" : "volume_off"
    }
    readonly property color outSliderColor: {
        if (outMuted) return Style.textDimmed
        if (outVol > 1.3) return Style.colorUrgent
        if (outOverdrive) return Style.accentAmber
        return Style.accentPink
    }

    // ── Input state ──
    readonly property real inVol: Pipewire.defaultAudioSource?.audio.volume ?? 0
    readonly property bool inMuted: Pipewire.defaultAudioSource?.audio.muted ?? false
    readonly property string inName: Pipewire.defaultAudioSource?.description ?? "No input"
    readonly property bool hasInput: {
        if (!Pipewire.defaultAudioSource) return false
        var name = Pipewire.defaultAudioSource.name ?? ""
        if (name.indexOf("monitor") >= 0) return false
        if (Pipewire.defaultAudioSource === Pipewire.defaultAudioSink) return false
        return true
    }
    readonly property color inLevelColor: {
        if (inMuted) return Style.textDimmed
        if (inVol > 0.9) return Style.colorUrgent
        if (inVol > 0.7) return Style.accentAmber
        return Style.colorGood
    }

    // ── Helper: detect device icon from name/description ──
    function sinkIconFor(node: PwNode): string {
        var n = ((node.name ?? "") + " " + (node.description ?? "")).toLowerCase()
        if (n.indexOf("hdmi") >= 0) return "tv"
        if (n.indexOf("headphone") >= 0 || n.indexOf("headset") >= 0) return "headphones"
        if (n.indexOf("bluetooth") >= 0 || n.indexOf("bluez") >= 0) return "bluetooth"
        if (n.indexOf("usb") >= 0) return "usb"
        return "speaker"
    }

    function sourceIconFor(node: PwNode): string {
        var n = ((node.name ?? "") + " " + (node.description ?? "")).toLowerCase()
        if (n.indexOf("webcam") >= 0) return "videocam"
        if (n.indexOf("headset") >= 0) return "headset_mic"
        if (n.indexOf("bluetooth") >= 0 || n.indexOf("bluez") >= 0) return "bluetooth"
        if (n.indexOf("usb") >= 0) return "usb"
        return "mic_none"
    }

    readonly property var nodeModel: Pipewire.nodes

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            readonly property real sf: modelData.height / 1080
            property bool _open: VolumeState.visible && VolumeState.screen === modelData
            visible: VolumeState.visible || card.opacity > 0
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore
            margins.top: Math.round(Style.barHeight * panel.sf)

            MouseArea {
                anchors.fill: parent
                onClicked: VolumeState.visible = false
            }

            // --- Dropdown Card ---
            Rectangle {
                id: card
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Math.round(Style.spaceMd * panel.sf)
                anchors.rightMargin: Math.round((Style.spaceMd + 200) * panel.sf)
                width: 340
                height: Math.min(cardContent.implicitHeight + Style.spaceXl * 2, panel.height - Style.spaceXl * 2)
                color: Style.bgSecondary
                radius: Style.radiusLg
                border.width: 1
                border.color: Style.bgTertiary
                clip: true

                opacity: panel._open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
                transform: Translate {
                    y: panel._open ? 0 : -8
                    Behavior on y { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
                }

                NeonStrip {}

                MouseArea { anchors.fill: parent }

                Flickable {
                    anchors.fill: parent
                    anchors.margins: Style.spaceXl
                    contentHeight: cardContent.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: cardContent
                        width: parent.width
                        spacing: 0

                        // ═══════════════════════════════════
                        // HEADER
                        // ═══════════════════════════════════

                        RowLayout {
                            spacing: Style.spaceMd

                            MaterialIcon {
                                text: "volume_up"
                                font.pixelSize: 20
                                color: Style.accentPink
                                fill: 1
                            }

                            StyledText {
                                text: "Volume"
                                font.pixelSize: Style.fontSizeXl
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            CloseButton { onClicked: VolumeState.visible = false }
                        }

                        // Neon header divider
                        Item { implicitHeight: Style.spaceMd }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 2
                            color: Style.accentPink
                            opacity: 0.6
                        }

                        Item { implicitHeight: Style.spaceLg }

                        // ═══════════════════════════════════
                        // SECTION 1: Output Volume
                        // ═══════════════════════════════════

                        // Output device name
                        StyledText {
                            text: root.outName
                            color: Style.textSecondary
                            font.pixelSize: Style.fontSizeSm
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Item { implicitHeight: Style.spaceSm }

                        // Output icon + percentage
                        RowLayout {
                            spacing: Style.spaceMd

                            MaterialIcon {
                                text: root.outIcon
                                font.pixelSize: 20
                                color: root.outSliderColor
                                fill: 1
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color { ColorAnimation { duration: Style.animFast } }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (Pipewire.defaultAudioSink?.audio)
                                            Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Overdrive warning icon
                            MaterialIcon {
                                text: "warning"
                                font.pixelSize: 16
                                color: Style.colorUrgent
                                visible: root.outOverdrive && !root.outMuted
                                Layout.alignment: Qt.AlignVCenter
                            }

                            StyledText {
                                text: Math.round(root.outVol * 100) + "%"
                                font.pixelSize: Style.fontSizeMd
                                font.bold: true
                                color: {
                                    if (root.outMuted) return Style.textDimmed
                                    if (root.outVol > 1.3) return Style.colorUrgent
                                    if (root.outOverdrive) return Style.accentAmber
                                    return Style.textPrimary
                                }

                                Behavior on color { ColorAnimation { duration: Style.animFast } }
                            }
                        }

                        Item { implicitHeight: Style.spaceSm }

                        // Output VU meter (15 segments: 0-150%)
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 10

                            VUMeter {
                                anchors.fill: parent
                                segments: 15; segmentHeight: 10
                                value: root.outVol / 1.5
                                muted: root.outMuted
                                warnAt: 0.7; critAt: 0.867
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                property bool isDragging: false

                                onPressed: mouse => { isDragging = true; setVol(mouse.x) }
                                onReleased: isDragging = false
                                onPositionChanged: mouse => { if (isDragging) setVol(mouse.x) }
                                onClicked: mouse => setVol(mouse.x)
                                onWheel: wheel => {
                                    if (Pipewire.defaultAudioSink?.audio) {
                                        var d = wheel.angleDelta.y / 120
                                        Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1.5, Pipewire.defaultAudioSink.audio.volume + d * 0.05))
                                    }
                                }

                                function setVol(x) {
                                    if (Pipewire.defaultAudioSink?.audio)
                                        Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1.5, x / width * 1.5))
                                }
                            }
                        }

                        // ── Input section (only if input device exists) ──
                        Item { implicitHeight: Style.spaceLg; visible: root.hasInput }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Style.bgTertiary
                            visible: root.hasInput
                        }

                        Item { implicitHeight: Style.spaceLg; visible: root.hasInput }

                        StyledText {
                            text: root.inName
                            color: Style.textSecondary
                            font.pixelSize: Style.fontSizeSm
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            visible: root.hasInput
                        }

                        Item { implicitHeight: Style.spaceSm; visible: root.hasInput }

                        // Input icon + percentage
                        RowLayout {
                            spacing: Style.spaceMd
                            visible: root.hasInput

                            MaterialIcon {
                                text: root.inMuted ? "mic_off" : "mic"
                                font.pixelSize: 20
                                color: root.inMuted ? Style.textDimmed : Style.accentPurple
                                fill: 1
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color { ColorAnimation { duration: Style.animFast } }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (Pipewire.defaultAudioSource?.audio)
                                            Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            StyledText {
                                text: Math.round(root.inVol * 100) + "%"
                                font.pixelSize: Style.fontSizeMd
                                font.bold: true
                                color: root.inMuted ? Style.textDimmed : Style.textPrimary
                            }
                        }

                        Item { implicitHeight: Style.spaceSm; visible: root.hasInput }

                        // Input VU meter (10 segments: 0-100%)
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 10
                            visible: root.hasInput

                            VUMeter {
                                anchors.fill: parent
                                segments: 10; segmentHeight: 10
                                value: root.inVol
                                muted: root.inMuted
                                baseColor: Style.colorGood; warnAt: 0.7; critAt: 0.9
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                property bool isDragging: false

                                onPressed: mouse => { isDragging = true; setVol(mouse.x) }
                                onReleased: isDragging = false
                                onPositionChanged: mouse => { if (isDragging) setVol(mouse.x) }
                                onClicked: mouse => setVol(mouse.x)
                                onWheel: wheel => {
                                    if (Pipewire.defaultAudioSource?.audio) {
                                        var d = wheel.angleDelta.y / 120
                                        Pipewire.defaultAudioSource.audio.volume = Math.max(0, Math.min(1.5, Pipewire.defaultAudioSource.audio.volume + d * 0.05))
                                    }
                                }

                                function setVol(x) {
                                    if (Pipewire.defaultAudioSource?.audio)
                                        Pipewire.defaultAudioSource.audio.volume = Math.max(0, Math.min(1.0, x / width))
                                }
                            }
                        }

                        // Input level meter (pulsing VU)
                        VUMeter {
                            Layout.fillWidth: true
                            visible: root.hasInput
                            segments: 10; segmentHeight: 4
                            value: root.inVol
                            muted: root.inMuted
                            baseColor: Style.colorGood; warnAt: 0.7; critAt: 0.9
                        }

                        Item { implicitHeight: Style.spaceLg }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Style.bgTertiary
                        }

                        Item { implicitHeight: Style.spaceLg }

                        // ═══════════════════════════════════
                        // SECTION 2: Applications
                        // ═══════════════════════════════════

                        RowLayout {
                            spacing: Style.spaceMd

                            MaterialIcon {
                                text: "apps"
                                font.pixelSize: 20
                                color: Style.accentPink
                                fill: 1
                            }

                            StyledText {
                                text: "Applications"
                                font.pixelSize: Style.fontSizeMd
                                font.bold: true
                            }
                        }

                        Item { implicitHeight: Style.spaceMd }

                        Repeater {
                            id: appRepeater
                            model: root.nodeModel

                            ColumnLayout {
                                id: appItem
                                required property PwNode modelData

                                readonly property bool isAppStream: modelData.isStream && modelData.audio !== null
                                readonly property string appName: modelData.description || modelData.nickname || modelData.name || "Unknown"
                                readonly property real appVol: modelData.audio?.volume ?? 0
                                readonly property bool appMuted: modelData.audio?.muted ?? false
                                readonly property bool appOverdrive: appVol > 1.0
                                property string appIconSource: ""
                                property int _iconRetries: 0

                                function resolveIcon(): void {
                                    if (!isAppStream) return
                                    var candidates = [
                                        modelData.name ?? "",
                                        modelData.nickname ?? "",
                                        modelData.description ?? ""
                                    ]
                                    for (var i = 0; i < candidates.length; i++) {
                                        var c = candidates[i].toLowerCase()
                                        if (c === "") continue
                                        var entry = DesktopEntries.byId(c) ?? DesktopEntries.heuristicLookup(c)
                                        if (entry && entry.icon) {
                                            appIconSource = Quickshell.iconPath(entry.icon)
                                            return
                                        }
                                    }
                                    // Retry if DesktopEntries hasn't loaded yet
                                    if (_iconRetries < 5) {
                                        _iconRetries++
                                        _iconRetryTimer.start()
                                    }
                                }

                                Timer {
                                    id: _iconRetryTimer
                                    interval: 500
                                    onTriggered: appItem.resolveIcon()
                                }

                                Component.onCompleted: resolveIcon()
                                readonly property color appSliderColor: {
                                    if (appMuted) return Style.textDimmed
                                    if (appVol > 1.3) return Style.colorUrgent
                                    if (appOverdrive) return Style.accentAmber
                                    return Style.accentPink
                                }

                                visible: isAppStream
                                Layout.fillWidth: true
                                spacing: Style.spaceSm

                                PwObjectTracker {
                                    objects: [appItem.modelData]
                                }

                                // App name + icon row
                                RowLayout {
                                    spacing: Style.spaceSm

                                    Image {
                                        id: appIconImg
                                        source: appItem.appIconSource
                                        visible: appItem.appIconSource !== "" && status === Image.Ready
                                        sourceSize.width: 16
                                        sourceSize.height: 16
                                        Layout.preferredWidth: 16
                                        Layout.preferredHeight: 16
                                    }

                                    MaterialIcon {
                                        text: "apps"
                                        font.pixelSize: 16
                                        color: Style.textDimmed
                                        visible: !appIconImg.visible
                                    }

                                    StyledText {
                                        text: appItem.appName
                                        color: Style.textSecondary
                                        font.pixelSize: Style.fontSizeSm
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    MaterialIcon {
                                        text: "warning"
                                        font.pixelSize: 14
                                        color: Style.colorUrgent
                                        visible: appItem.appOverdrive && !appItem.appMuted
                                    }

                                    MaterialIcon {
                                        text: appItem.appMuted ? "volume_off" : "volume_up"
                                        font.pixelSize: 16
                                        color: appItem.appSliderColor
                                        fill: 1

                                        Behavior on color { ColorAnimation { duration: Style.animFast } }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (appItem.modelData.audio)
                                                    appItem.modelData.audio.muted = !appItem.modelData.audio.muted
                                            }
                                        }
                                    }

                                    StyledText {
                                        text: Math.round(appItem.appVol * 100) + "%"
                                        font.pixelSize: Style.fontSizeSm
                                        font.bold: true
                                        color: {
                                            if (appItem.appMuted) return Style.textDimmed
                                            if (appItem.appOverdrive) return Style.colorUrgent
                                            return Style.textPrimary
                                        }
                                        Layout.preferredWidth: 38
                                        horizontalAlignment: Text.AlignRight

                                        Behavior on color { ColorAnimation { duration: Style.animFast } }
                                    }
                                }

                                // App VU meter (15 segments: 0-150%)
                                Item {
                                    Layout.fillWidth: true
                                    implicitHeight: 8

                                    VUMeter {
                                        anchors.fill: parent
                                        segments: 15
                                        value: appItem.appVol / 1.5
                                        muted: appItem.appMuted
                                        warnAt: 0.7; critAt: 0.867
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        property bool isDragging: false

                                        onPressed: mouse => { isDragging = true; setVol(mouse.x) }
                                        onReleased: isDragging = false
                                        onPositionChanged: mouse => { if (isDragging) setVol(mouse.x) }
                                        onClicked: mouse => setVol(mouse.x)
                                        onWheel: wheel => {
                                            if (appItem.modelData.audio) {
                                                var d = wheel.angleDelta.y / 120
                                                appItem.modelData.audio.volume = Math.max(0, Math.min(1.5, appItem.modelData.audio.volume + d * 0.05))
                                            }
                                        }

                                        function setVol(x) {
                                            if (appItem.modelData.audio)
                                                appItem.modelData.audio.volume = Math.max(0, Math.min(1.5, x / width * 1.5))
                                        }
                                    }
                                }

                                Item { implicitHeight: Style.spaceSm }
                            }
                        }

                        // Placeholder when no apps are playing
                        StyledText {
                            text: "No applications playing"
                            color: Style.textDimmed
                            font.pixelSize: Style.fontSizeSm
                            visible: {
                                void appRepeater.count
                                for (var i = 0; i < appRepeater.count; i++) {
                                    var item = appRepeater.itemAt(i)
                                    if (item && item.isAppStream) return false
                                }
                                return true
                            }
                        }

                        Item { implicitHeight: Style.spaceLg }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Style.bgTertiary
                        }

                        Item { implicitHeight: Style.spaceLg }

                        // ═══════════════════════════════════
                        // SECTION 3: Playback Device
                        // ═══════════════════════════════════

                        RowLayout {
                            spacing: Style.spaceMd

                            MaterialIcon {
                                text: "speaker"
                                font.pixelSize: 20
                                color: Style.accentPink
                                fill: 1
                            }

                            StyledText {
                                text: "Playback Device"
                                font.pixelSize: Style.fontSizeMd
                                font.bold: true
                            }
                        }

                        Item { implicitHeight: Style.spaceMd }

                        Repeater {
                            model: root.nodeModel

                            Rectangle {
                                id: sinkItem
                                required property PwNode modelData

                                readonly property bool isSinkDevice: modelData.isSink && !modelData.isStream && modelData.audio !== null
                                readonly property bool isDefault: Pipewire.defaultAudioSink === modelData
                                readonly property string deviceIcon: root.sinkIconFor(modelData)

                                visible: isSinkDevice
                                Layout.fillWidth: true
                                implicitHeight: isSinkDevice ? sinkRow.implicitHeight + Style.spaceMd * 2 : 0
                                radius: Style.radiusSm
                                color: sinkHover.containsMouse
                                    ? Style.pinkHover
                                    : "transparent"

                                Behavior on color { ColorAnimation { duration: Style.animFast } }

                                RowLayout {
                                    id: sinkRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Style.spaceMd
                                    spacing: Style.spaceMd

                                    MaterialIcon {
                                        text: sinkItem.deviceIcon
                                        font.pixelSize: 18
                                        color: sinkItem.isDefault ? Style.accentPink : Style.textDimmed
                                        fill: sinkItem.isDefault ? 1 : 0
                                    }

                                    StyledText {
                                        text: sinkItem.modelData.description || sinkItem.modelData.name || "Unknown"
                                        font.pixelSize: Style.fontSizeSm
                                        font.bold: sinkItem.isDefault
                                        color: sinkItem.isDefault ? Style.accentPink : Style.textPrimary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    MaterialIcon {
                                        text: "check_circle"
                                        font.pixelSize: 16
                                        color: Style.accentPink
                                        visible: sinkItem.isDefault
                                        fill: 1
                                    }
                                }

                                MouseArea {
                                    id: sinkHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Pipewire.preferredDefaultAudioSink = sinkItem.modelData
                                    }
                                }
                            }
                        }

                        Item { implicitHeight: Style.spaceLg }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Style.bgTertiary
                        }

                        Item { implicitHeight: Style.spaceLg }

                        // ═══════════════════════════════════
                        // SECTION 4: Input Device
                        // ═══════════════════════════════════

                        RowLayout {
                            spacing: Style.spaceMd

                            MaterialIcon {
                                text: "mic"
                                font.pixelSize: 20
                                color: Style.accentPurple
                                fill: 1
                            }

                            StyledText {
                                text: "Input Device"
                                font.pixelSize: Style.fontSizeMd
                                font.bold: true
                            }
                        }

                        Item { implicitHeight: Style.spaceMd }

                        Repeater {
                            model: root.nodeModel

                            Rectangle {
                                id: sourceItem
                                required property PwNode modelData

                                readonly property bool isSourceDevice: !modelData.isSink && !modelData.isStream && modelData.audio !== null && (modelData.name ?? "").indexOf("monitor") < 0
                                readonly property bool isDefault: Pipewire.defaultAudioSource === modelData
                                readonly property string deviceIcon: root.sourceIconFor(modelData)

                                visible: isSourceDevice
                                Layout.fillWidth: true
                                implicitHeight: isSourceDevice ? sourceRow.implicitHeight + Style.spaceMd * 2 : 0
                                radius: Style.radiusSm
                                color: sourceHover.containsMouse
                                    ? Style.purpleHover
                                    : "transparent"

                                Behavior on color { ColorAnimation { duration: Style.animFast } }

                                RowLayout {
                                    id: sourceRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Style.spaceMd
                                    spacing: Style.spaceMd

                                    MaterialIcon {
                                        text: sourceItem.deviceIcon
                                        font.pixelSize: 18
                                        color: sourceItem.isDefault ? Style.accentPurple : Style.textDimmed
                                        fill: sourceItem.isDefault ? 1 : 0
                                    }

                                    StyledText {
                                        text: sourceItem.modelData.description || sourceItem.modelData.name || "Unknown"
                                        font.pixelSize: Style.fontSizeSm
                                        font.bold: sourceItem.isDefault
                                        color: sourceItem.isDefault ? Style.accentPurple : Style.textPrimary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    MaterialIcon {
                                        text: "check_circle"
                                        font.pixelSize: 16
                                        color: Style.accentPurple
                                        visible: sourceItem.isDefault
                                        fill: 1
                                    }
                                }

                                MouseArea {
                                    id: sourceHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Pipewire.preferredDefaultAudioSource = sourceItem.modelData
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
