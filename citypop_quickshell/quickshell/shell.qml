//@ pragma IconTheme Tela-circle-pink

import Quickshell
import "modules/bar"
import "modules/notifications"
import "modules/osd"
import "modules/launcher"
import "modules/lock"
import "modules/wallpaper"

Scope {
    // Wallpaper {}
    Bar {}
    NotificationPopup {}
    NotificationHistory {}
    OSD {}
    Launcher { id: launcher }
    LockScreen { id: lockScreen }
}
