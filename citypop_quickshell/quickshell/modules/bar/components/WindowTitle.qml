import QtQuick
import Quickshell.Hyprland
import "../../../Singleton"
import "../../../common"

StyledText {
    property real sf: 1.0

    text: {
        var title = Hyprland.focusedToplevel?.title ?? ""
        return title.length > 50 ? title.substring(0, 47) + "..." : title
    }
    color: Style.textSecondary
    font.pixelSize: Math.round(Style.fontSizeSm * sf)
    elide: Text.ElideRight
}
