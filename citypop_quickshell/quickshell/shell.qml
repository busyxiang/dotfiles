//@ pragma UseQApplication
//@ pragma IconTheme Tela-circle-pink

import Quickshell
import "modules/bar"
import "modules/notifications"
import "modules/osd"
import "modules/launcher"
import "modules/lock"
import "modules/wallpaper"
import "modules/network"
import "modules/bluetooth"
import "modules/powermenu"
import "modules/systray"
import "modules/calendar"
import "modules/volume"
import "modules/sysmon"

Scope {
    // Wallpaper {}
    Bar {}
    NetworkPanel {}
    BluetoothPanel {}
    PowerMenuPanel {}
    TrayMenuPanel {}
    CalendarPanel {}
    VolumePanel {}
    SysMonPanel {}
    NotificationPopup {}
    NotificationHistory {}
    OSD {}
    Launcher { id: launcher }
    LockScreen { id: lockScreen }
}
