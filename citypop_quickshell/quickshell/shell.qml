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
import "modules/weather"
import "modules/updates"
import "modules/clipboard"
import "modules/lock"

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
    WeatherPanel {}
    UpdatePanel {}
    ClipboardPanel {}
    NotificationPopup {}
    NotificationHistory {}
    OSD {}
    LockScreen {}
}
