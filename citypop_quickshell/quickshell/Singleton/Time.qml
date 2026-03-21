pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property string time: Qt.formatDateTime(clock.date, "hh:mm AP")
    readonly property string date: Qt.formatDateTime(clock.date, "ddd, MMM d")
    readonly property string fullTime: Qt.formatDateTime(clock.date, "hh:mm:ss AP | dddd, MMM d")

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
