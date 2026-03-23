pragma ComponentBehavior: Bound

import QtQuick
import "../Singleton"

// Reusable VU meter — segmented bar with threshold-based coloring.
// All values are normalized 0.0–1.0.
Item {
    id: vu

    property int segments: 20
    property real value: 0          // 0.0 – 1.0
    property bool muted: false
    property int segmentHeight: 8
    property int segmentSpacing: 2
    property int segmentRadius: 1

    // Colors
    property color baseColor: Style.accentPink
    property color warnColor: Style.accentAmber
    property color critColor: Style.colorUrgent
    property color offColor: Style.bgTertiary

    // Threshold fractions (0.0–1.0) where color changes
    property real warnAt: 0.7       // fraction where warnColor starts
    property real critAt: 0.9       // fraction where critColor starts

    // Animation
    property int animDuration: Style.animFast

    implicitHeight: segmentHeight

    Row {
        id: row
        anchors.fill: parent
        spacing: vu.segmentSpacing

        Repeater {
            model: vu.segments

            Rectangle {
                required property int index

                width: (row.width - (vu.segments - 1) * row.spacing) / vu.segments
                height: vu.segmentHeight
                radius: vu.segmentRadius

                readonly property real segFraction: (index + 1) / vu.segments
                readonly property bool isLit: !vu.muted && vu.value >= segFraction - (0.5 / vu.segments)

                color: {
                    if (!isLit) return vu.offColor
                    if (vu.critAt < 1.0 && segFraction > vu.critAt) return vu.critColor
                    if (vu.warnAt < 1.0 && segFraction > vu.warnAt) return vu.warnColor
                    return vu.baseColor
                }

                Behavior on color { ColorAnimation { duration: vu.animDuration } }
            }
        }
    }
}
