import QtQuick
import "../Singleton"

// Split-flap style digit that rolls vertically on change.
// Parent must set a fixed width/height.
Item {
    id: flipDigit

    property string value: "0"
    property real textSize: Style.fontSizeMd
    property bool bold: true
    property string textColor: Style.accentPink
    property string bgColor: "transparent"
    property int animDuration: 180

    clip: true

    // Track old value for transition
    property string _prev: value
    property string _current: value
    property real _progress: 1.0  // 0 = showing old, 1 = showing new

    onValueChanged: {
        if (value !== _current) {
            _prev = _current
            _current = value
            _progress = 0
            flipAnim.start()
        }
    }

    NumberAnimation {
        id: flipAnim
        target: flipDigit
        property: "_progress"
        from: 0; to: 1
        duration: flipDigit.animDuration
        easing.type: Easing.OutCubic
    }

    // Background card
    Rectangle {
        anchors.fill: parent
        radius: Style.radiusSm
        color: flipDigit.bgColor
    }

    // Old digit (slides up and fades)
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - implicitHeight / 2 - flipDigit._progress * parent.height * 0.6
        text: flipDigit._prev
        font.family: Style.fontFamily
        font.pixelSize: flipDigit.textSize
        font.bold: flipDigit.bold
        color: flipDigit.textColor
        opacity: 1.0 - flipDigit._progress
        renderType: Text.NativeRendering
    }

    // New digit (slides in from below)
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2 - implicitHeight / 2 + (1.0 - flipDigit._progress) * parent.height * 0.6
        text: flipDigit._current
        font.family: Style.fontFamily
        font.pixelSize: flipDigit.textSize
        font.bold: flipDigit.bold
        color: flipDigit.textColor
        opacity: flipDigit._progress
        renderType: Text.NativeRendering
    }
}
