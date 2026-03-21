import QtQuick
import "../Singleton"

Text {
    property real fill: 0  // 0 = outlined, 1 = filled
    property int grade: 0

    font.family: "Material Symbols Rounded"
    font.pixelSize: 24

    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: Style.textPrimary
    antialiasing: true

    Component.onCompleted: {
        font.variableAxes = {
            "FILL": fill,
            "GRAD": grade,
            "opsz": 24,
            "wght": 400
        };
    }
}
