pragma Singleton

import Quickshell
import "../modules/volume"
import "../modules/calendar"
import "../modules/sysmon"
import "../modules/powermenu"
import "../modules/media"
import "../modules/bluetooth"
import "../modules/network"
import "../modules/notifications"
import "../modules/weather"

Singleton {
    function closeAll() {
        VolumeState.visible = false
        CalendarState.visible = false
        SysMonState.visible = false
        PowerMenuState.visible = false
        MediaState.visible = false
        BluetoothManager.panelVisible = false
        NetworkManager.panelVisible = false
        NotificationManager.historyVisible = false
        WeatherState.visible = false
    }
}
