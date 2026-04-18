pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool visible: false
    property var screen: null
    property real panelX: 0

    // Tooltip state
    property bool tooltipVisible: false
    property var tooltipScreen: null
    property real tooltipX: 0

    // --- Location management ---
    readonly property var locations: [
        { name: "Kuala Lumpur", lat: 3.1390, lon: 101.6869 },
        { name: "Ipoh",         lat: 4.5975, lon: 101.0901 }
    ]
    property int activeLocation: 0  // index into locations[]

    // --- Current conditions (per location) ---
    property var locationData: []  // array of { temp, feelsLike, humidity, windSpeed, uvIndex, weatherCode, isDay, high, low, description, forecast[] }

    // Convenience: active location's data
    readonly property var current: locationData.length > activeLocation ? locationData[activeLocation] : null

    // --- WMO Weather Code → description + Material icon ---
    function weatherInfo(code: int, isDay: bool): var {
        var map = {
            0:  { desc: "Clear sky",           icon: isDay ? "clear_day"           : "clear_night" },
            1:  { desc: "Mainly clear",        icon: isDay ? "clear_day"           : "clear_night" },
            2:  { desc: "Partly cloudy",       icon: isDay ? "partly_cloudy_day"   : "partly_cloudy_night" },
            3:  { desc: "Overcast",            icon: "cloud" },
            45: { desc: "Foggy",               icon: "foggy" },
            48: { desc: "Depositing rime fog", icon: "foggy" },
            51: { desc: "Light drizzle",       icon: "rainy_light" },
            53: { desc: "Moderate drizzle",    icon: "rainy_light" },
            55: { desc: "Dense drizzle",       icon: "rainy" },
            56: { desc: "Freezing drizzle",    icon: "weather_snowy" },
            57: { desc: "Heavy freezing drizzle", icon: "weather_snowy" },
            61: { desc: "Slight rain",         icon: "rainy_light" },
            63: { desc: "Moderate rain",       icon: "rainy" },
            65: { desc: "Heavy rain",          icon: "rainy_heavy" },
            66: { desc: "Freezing rain",       icon: "weather_snowy" },
            67: { desc: "Heavy freezing rain", icon: "weather_snowy" },
            71: { desc: "Slight snow",         icon: "weather_snowy" },
            73: { desc: "Moderate snow",       icon: "weather_snowy" },
            75: { desc: "Heavy snow",          icon: "weather_snowy" },
            77: { desc: "Snow grains",         icon: "weather_snowy" },
            80: { desc: "Slight showers",      icon: "rainy_light" },
            81: { desc: "Moderate showers",    icon: "rainy" },
            82: { desc: "Violent showers",     icon: "rainy_heavy" },
            85: { desc: "Slight snow showers", icon: "weather_snowy" },
            86: { desc: "Heavy snow showers",  icon: "weather_snowy" },
            95: { desc: "Thunderstorm",        icon: "thunderstorm" },
            96: { desc: "Thunderstorm with hail", icon: "thunderstorm" },
            99: { desc: "Thunderstorm with heavy hail", icon: "thunderstorm" }
        }
        return map[code] || { desc: "Unknown", icon: "help" }
    }

    function windCardinal(deg: real): string {
        var dirs = ["N","NE","E","SE","S","SW","W","NW"]
        return dirs[Math.round(deg / 45) % 8]
    }

    // --- Fetch logic ---
    property int _fetchIndex: 0
    property var _pendingData: []
    property bool fetchError: false
    property int _retryCount: 0
    readonly property int _maxRetries: 3
    readonly property var _retryDelays: [60000, 120000, 300000]  // 1min, 2min, 5min
    property bool retrying: false

    Timer {
        interval: 30 * 60 * 1000  // 30 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._retryCount = 0
            root.retrying = false
            root.fetchAll()
        }
    }

    Timer {
        id: retryTimer
        repeat: false
        onTriggered: {
            root.retrying = false
            root.fetchAll()
        }
    }

    property bool _fetching: false

    function resetRetry(): void {
        _retryCount = 0
        retrying = false
    }

    function fetchAll(): void {
        if (_fetching) return
        _fetching = true
        _pendingData = []
        _fetchIndex = 0
        fetchError = false
        _startFetch()
    }

    function _scheduleRetry(): void {
        if (_retryCount < _maxRetries) {
            retrying = true
            retryTimer.interval = _retryDelays[_retryCount]
            _retryCount++
            retryTimer.start()
        } else {
            retrying = false
            fetchError = true
        }
    }

    function _startFetch(): void {
        if (_fetchIndex >= locations.length) {
            _fetching = false
            var allFailed = _pendingData.every(function(d) { return d === null })
            if (allFailed && _pendingData.length > 0) {
                _scheduleRetry()
            } else {
                locationData = _pendingData
                fetchError = false
                _retryCount = 0
                retrying = false
            }
            return
        }
        var loc = locations[_fetchIndex]
        fetchProc.command = [
            "curl", "-sf", "--max-time", "15",
            "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + loc.lat
            + "&longitude=" + loc.lon
            + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,is_day,wind_speed_10m,wind_direction_10m,uv_index"
            + "&hourly=temperature_2m,weather_code,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"
            + "&timezone=auto"
            + "&forecast_days=5"
            + "&forecast_hours=12"
        ]
        fetchProc.running = true
    }

    Process {
        id: fetchProc
        property string _buf: ""
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => { fetchProc._buf = data }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && fetchProc._buf.length > 0) {
                try {
                    var json = JSON.parse(fetchProc._buf)
                    var c = json.current
                    var d = json.daily
                    var info = root.weatherInfo(c.weather_code, c.is_day === 1)

                    var forecast = []
                    for (var i = 0; i < d.time.length; i++) {
                        var dayInfo = root.weatherInfo(d.weather_code[i], true)
                        forecast.push({
                            date: d.time[i],
                            high: Math.round(d.temperature_2m_max[i]),
                            low: Math.round(d.temperature_2m_min[i]),
                            weatherCode: d.weather_code[i],
                            icon: dayInfo.icon,
                            description: dayInfo.desc
                        })
                    }

                    // Extract today's sunrise/sunset (strip date, keep HH:MM)
                    var sunrise = d.sunrise && d.sunrise[0] ? d.sunrise[0].substring(11) : ""
                    var sunset  = d.sunset  && d.sunset[0]  ? d.sunset[0].substring(11)  : ""

                    // Hourly forecast — next 6 hours from now
                    var hourly = []
                    var h = json.hourly
                    if (h && h.time && h.time.length > 0) {
                        var nowMs = Date.now()
                        var found = 0
                        for (var hi = 0; hi < h.time.length && found < 6; hi++) {
                            var hourMs = new Date(h.time[hi]).getTime()
                            if (hourMs > nowMs) {
                                var hInfo = root.weatherInfo(h.weather_code[hi], h.is_day[hi] === 1)
                                hourly.push({
                                    time: h.time[hi],
                                    hour: new Date(h.time[hi]).getHours(),
                                    temp: Math.round(h.temperature_2m[hi]),
                                    weatherCode: h.weather_code[hi],
                                    icon: hInfo.icon,
                                    description: hInfo.desc
                                })
                                found++
                            }
                        }
                    }

                    root._pendingData.push({
                        temp: Math.round(c.temperature_2m),
                        feelsLike: Math.round(c.apparent_temperature),
                        humidity: c.relative_humidity_2m,
                        windSpeed: Math.round(c.wind_speed_10m),
                        windDirection: c.wind_direction_10m,
                        uvIndex: Math.round(c.uv_index),
                        weatherCode: c.weather_code,
                        isDay: c.is_day === 1,
                        description: info.desc,
                        icon: info.icon,
                        high: forecast.length > 0 ? forecast[0].high : 0,
                        low: forecast.length > 0 ? forecast[0].low : 0,
                        sunrise: sunrise,
                        sunset: sunset,
                        fetchedAt: Qt.formatTime(new Date(), "h:mm AP"),
                        forecast: forecast,
                        hourly: hourly
                    })
                } catch (e) {
                    // Parse failed — push empty entry to keep indices aligned
                    root._pendingData.push(null)
                }
            } else {
                root._pendingData.push(null)
            }
            fetchProc._buf = ""
            root._fetchIndex++
            root._startFetch()
        }
    }
}
