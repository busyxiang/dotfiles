pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property string time: {
        Qt.formatDateTime(clock.date, "hh:mm:ss AP | dddd");
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
