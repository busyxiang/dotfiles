//@ pragma UseQApplication
//@ pragma IconTheme Tela-circle-pink

import Quickshell
import "modules/bar"
import "modules/notifications"
import "modules/osd"
import "modules/network"
import "modules/bluetooth"
import "modules/powermenu"
import "modules/systray"
import "modules/calendar"
import "modules/volume"
import "modules/sysmon"
import "modules/media"

Scope {

    Bar {}
    NetworkPanel {}
    BluetoothPanel {}
    PowerMenuPanel {}
    TrayMenuPanel {}
    CalendarPanel {}
    VolumePanel {}
    SysMonPanel {}
    MediaPanel {}
    NotificationPopup {}
    NotificationHistory {}
    OSD {}
}
