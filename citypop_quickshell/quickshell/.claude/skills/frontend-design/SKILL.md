## <!-- markdownlint-disable MD041 -->

name: frontend-design
description: Design and build distinctive QML widgets and panels for the City Pop Quickshell desktop. Uses the project's Style tokens, common components, panel patterns, and learned QML gotchas to produce polished, correct interfaces.
license: Complete terms in LICENSE.txt

---

# Frontend Design Skill — City Pop Quickshell

Guide the creation of high-quality QML interfaces for a Wayland desktop shell built with Quickshell. The aesthetic is **late-night city pop** — dark backgrounds, neon pink accents, warm amber warnings, and retro-futuristic polish.

## Design Thinking

Before writing code, answer these:

1. **Context**: Where does this widget live? Bar widget, dropdown panel, OSD, popup?
2. **Aesthetic fit**: Does it feel like it belongs in a neon-lit Tokyo side street at 2AM?
3. **Differentiation**: What makes this widget feel alive? A subtle glow, a spinning vinyl, a pulsing VU meter?
4. **Restraint**: Bold accents work because the base is dark and minimal. Don't overdo it.

## Color Palette (Style singleton)

All colors come from `Singleton/Style.qml`. Never hardcode colors.

### Backgrounds (dark-to-light)
| Token | Hex | Use |
|-------|-----|-----|
| `Style.bgPrimary` | #1a0a2e | Base/bar background |
| `Style.bgSecondary` | #2b1b3d | Card/panel backgrounds |
| `Style.bgTertiary` | #3d2b4f | Hover states, off segments, dividers |

### Accents
| Token | Hex | Use |
|-------|-----|-----|
| `Style.accentPink` | #ff69b4 | Primary accent — active states, highlights, neon strips |
| `Style.accentMagenta` | #ff1493 | Stronger pink for emphasis |
| `Style.accentAmber` | #ffb347 | Warnings, elevated volume, caution states |
| `Style.accentPurple` | #da70d6 | Secondary accent, variety |
| `Style.colorUrgent` | #ff4466 | Critical — urgent notifications, overdrive volume |
| `Style.colorGood` | #66bb6a | Success — connected, healthy |

### Derived alpha tints (hover/border/glow)
- Pink: `pinkHover`, `pinkBorder`, `pinkGradientStart`, `pinkGradientEnd`
- Urgent: `urgentHover`, `urgentBg`, `urgentBgStrong`, `urgentBorder`, `urgentGlow`
- Amber: `amberBg`, `amberBorder`, `amberGlow`
- Purple: `purpleHover`

### Text hierarchy
| Token | Hex | Use |
|-------|-----|-----|
| `Style.textPrimary` | #f0e6f6 | Headings, primary labels |
| `Style.textSecondary` | #b8a9c9 | Body text, descriptions |
| `Style.textDimmed` | #6b5b7b | Inactive, muted, timestamps |

## Spacing, Radii, and Type Scale

### Spacing (px)
`spaceXs: 2` · `spaceSm: 4` · `spaceMd: 8` · `spaceLg: 12` · `spaceXl: 16`

### Border radii
`radiusSm: 4` · `radiusMd: 8` · `radiusLg: 12` · `radiusFull: 999`

### Font sizes
`fontSizeSm: 13` · `fontSizeMd: 15` · `fontSizeLg: 17` · `fontSizeXl: 20`

### Bar dimensions
`barHeight: 36` · `barPadding: 8`

### Animation durations
`animFast: 120` · `animNormal: 200` · `animSlow: 350`

## Common Components (common/)

Use these instead of rebuilding from scratch:

### StyledText
Text with project font (CaskaydiaCove Nerd Font) and native rendering.
```qml
StyledText { text: "Label"; font.pixelSize: Style.fontSizeMd; color: Style.textPrimary }
```

### MaterialIcon
Material Symbols Rounded icon with fill control.
```qml
MaterialIcon { text: "volume_up"; font.pixelSize: 24; color: Style.accentPink; fill: 1 }
```

### VUMeter
Segmented bar with threshold-based coloring. Value is normalized 0.0–1.0.
```qml
VUMeter {
    segments: 20; value: 0.75; muted: false
    baseColor: Style.accentPink; warnAt: 0.7; critAt: 0.9
    segmentHeight: 8; segmentSpacing: 2; animDuration: Style.animFast
}
```

### CloseButton
28x28 circular close button with hover effect. Emits `clicked()`.
```qml
CloseButton { onClicked: SomeState.visible = false }
```

### NeonStrip
2px accent strip anchored to parent top. Decorative top border for panels.
```qml
NeonStrip {} // anchors to parent top automatically
```

## Architecture Patterns

### Imports
```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire  // or .Mpris, .Notifications, etc.
import "../../Singleton"              // Style, PanelManager
import "../../common"                 // StyledText, MaterialIcon, VUMeter, etc.
```

### Panel pattern (dropdown from bar)
Every panel follows this structure:

1. **State singleton** (`modules/<name>/<Name>State.qml`) — holds `visible` and `screen`
2. **Panel component** (`modules/<name>/<Name>Panel.qml`) — the UI
3. **Bar widget** opens panel via `PanelManager.closeAll()` then sets state

```qml
// State singleton
pragma Singleton
import Quickshell
Singleton {
    property bool visible: false
    property var screen: null
}

// Bar widget click handler
onClicked: {
    var wasOpen = MyState.visible
    PanelManager.closeAll()
    if (!wasOpen) {
        MyState.screen = root.screen
        MyState.visible = true
    }
}
```

### Panel window with animation
```qml
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: panel
        required property var modelData
        screen: modelData
        readonly property real sf: modelData.height / 1080  // per-monitor scale
        property bool _open: MyState.visible && MyState.screen === modelData
        visible: MyState.visible || card.opacity > 0  // stay visible during fade-out
        color: "transparent"

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        margins.top: Math.round(Style.barHeight * panel.sf)  // bar passthrough

        // Click-outside to close
        MouseArea {
            anchors.fill: parent
            onClicked: MyState.visible = false
        }

        // Card with fade + slide animation
        Rectangle {
            id: card
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: Math.round(Style.spaceMd * panel.sf)
            anchors.rightMargin: Math.round(Style.spaceMd * panel.sf)
            width: 300
            color: Style.bgSecondary
            radius: Style.radiusLg
            border.width: 1
            border.color: Style.bgTertiary

            opacity: panel._open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
            transform: Translate {
                y: panel._open ? 0 : -8
                Behavior on y { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
            }

            // Block click-through to overlay
            MouseArea { anchors.fill: parent }

            NeonStrip {}

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.spaceXl
                spacing: Style.spaceLg
                // ... content
            }
        }
    }
}
```

### Bar widget pattern
```qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../Singleton"
import "../../common"

Item {
    id: root
    property real sf: 1.0
    property var screen: null
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Math.round(Style.spaceMd * root.sf)
        // ... content
    }
}
```

## Animation Guidelines

### Standard easing
- **Open/show**: `Easing.OutCubic` — fast start, gentle settle
- **Close/hide**: `Easing.InCubic` or `Easing.OutCubic`
- **Hover**: `Easing.InOutQuad` or just use `animFast` duration

### Preferred patterns
```qml
// Property behavior (simple)
Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
Behavior on color { ColorAnimation { duration: Style.animFast } }

// Slide + fade (panels)
opacity: isOpen ? 1 : 0
transform: Translate { y: isOpen ? 0 : -8 }

// Hover color change
color: hoverArea.containsMouse ? Style.bgTertiary : "transparent"
Behavior on color { ColorAnimation { duration: Style.animFast } }
```

## Additional Patterns

### API fetching with Process + curl
For external data (weather, etc.), use `Process` with curl and `SplitParser` to parse JSON responses.
```qml
Process {
    id: fetchProc
    property string _buf: ""
    stdout: SplitParser {
        splitMarker: ""  // capture full output
        onRead: data => { fetchProc._buf = data }
    }
    onExited: (exitCode, exitStatus) => {
        if (exitCode === 0 && fetchProc._buf.length > 0) {
            try {
                var json = JSON.parse(fetchProc._buf)
                // ... process data
            } catch (e) { /* handle error */ }
        }
        fetchProc._buf = ""
    }
}

// Trigger with timer
Timer {
    interval: 30 * 60 * 1000
    running: true; repeat: true; triggeredOnStart: true
    onTriggered: {
        fetchProc.command = ["curl", "-sf", url]
        fetchProc.running = true
    }
}
```

### Tooltip pattern (bar widget hover)
For bar widget tooltips, use state properties on the singleton + a separate `Variants`/`PanelWindow` in the panel file.

**State singleton:**
```qml
property bool tooltipVisible: false
property var tooltipScreen: null
property real tooltipX: 0
```

**Bar widget MouseArea:**
```qml
MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onContainsMouseChanged: {
        if (containsMouse && !MyState.visible) {
            var globalPos = root.mapToItem(null, root.width / 2, 0)
            MyState.tooltipX = globalPos.x
            MyState.tooltipScreen = root.screen
            MyState.tooltipVisible = true
        } else {
            MyState.tooltipVisible = false
        }
    }
    onClicked: {
        MyState.tooltipVisible = false
        // ... open panel
    }
}
```

**Tooltip PanelWindow** (in panel file, second `Variants` block):
```qml
Variants {
    model: Quickshell.screens
    PanelWindow {
        required property var modelData
        screen: modelData
        visible: tipContent.opacity > 0 && MyState.tooltipScreen === modelData
        color: "transparent"; focusable: false
        anchors { top: true; left: true; right: true }
        implicitHeight: Style.barHeight + Style.spaceMd + 60
        exclusionMode: ExclusionMode.Ignore

        Item {
            id: tipContent
            x: MyState.tooltipX - width / 2
            y: Style.barHeight + Style.spaceSm
            // ... arrow pointer + card with NeonStrip
        }
    }
}
```

### Stat card grid (2x2 or NxN detail cards)
Use `GridLayout` with `Layout.fillWidth: true` and `Layout.fillHeight: true` on each card for uniform sizing.
```qml
GridLayout {
    Layout.fillWidth: true
    columns: 2
    columnSpacing: Style.spaceSm
    rowSpacing: Style.spaceSm

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitHeight: content.implicitHeight + Style.spaceLg * 2
        radius: Style.radiusMd
        color: Style.bgTertiary
        // ... centered ColumnLayout content
    }
    // ... more cards
}
```

### Error/retry with exponential backoff
For modules that fetch external data, use this retry pattern in the State singleton:
```qml
property bool fetchError: false
property bool retrying: false
property int _retryCount: 0
readonly property int _maxRetries: 3
readonly property var _retryDelays: [60000, 120000, 300000]  // 1m, 2m, 5m
property bool _fetching: false  // overlap guard

function _scheduleRetry() {
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

Timer {
    id: retryTimer
    onTriggered: { root.retrying = false; root.fetchAll() }
}

function fetchAll() {
    if (_fetching) return  // prevent overlapping fetches
    _fetching = true
    fetchError = false
    // ... start Process
}
```
Bar widgets show retry state with a pulse animation (slower 1200ms during retry) and amber `!` error badge.

### Process overlap and chaining
Always guard against concurrent Process runs:
```qml
// Overlap guard — prevent re-entry
function checkUpdates() {
    if (checking) return
    checking = true
    proc.running = true
}

// Sequential chaining — run procB after procA
Process {
    id: procA
    onExited: (code, status) => {
        // process procA output, then:
        procB.running = true
    }
}
Process {
    id: procB
    onExited: (code, status) => {
        // finalize
        root.checking = false
    }
}
```

### Crossfade animation (content swap)
For swapping displayed data (e.g. switching locations), use a quick fade-out/fade-in on a shared opacity property.
```qml
property real contentOpacity: 1.0

Connections {
    target: SomeState
    function onActiveItemChanged() { fadeAnim.start() }
}

SequentialAnimation {
    id: fadeAnim
    NumberAnimation { target: container; property: "contentOpacity"; to: 0; duration: 100; easing.type: Easing.InCubic }
    NumberAnimation { target: container; property: "contentOpacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
}

// Apply to content sections:
// opacity: container.contentOpacity
```

## QML Gotchas (learned from experience)

These are critical — violating them causes bugs that are hard to diagnose:

1. **Never use `scale` on panels with text** — QML `scale` is a bitmap transform that makes all text blurry. Scale margins/spacing instead.

2. **Repeater + JS array reassignment rebuilds ALL delegates** — Every `array = newArray` destroys and recreates every delegate, breaking animations. Use tracking arrays to avoid rebuilds during animations.

3. **Imperative property assignment breaks declarative bindings** — `opacity = 0` in Component.onCompleted permanently disconnects the binding. Use property initialization or state flags instead.

4. **`Behavior on property` animates initial values** — New delegates will animate from default to target. Use a `_appeared` flag pattern with `_knownIds` map to control which items should animate.

5. **`margins.top` on PanelWindow offsets the layer-shell input region** — This lets clicks pass through to the bar underneath. Essential for bar passthrough on panels.

6. **MPRIS `trackArtists` can be a string** — Firefox returns a string, not an array. Always check `typeof artists === "string"` before indexing.

7. **ColumnLayout height animation causes sibling flicker** — Animating item height in a ColumnLayout forces recalculation on all siblings. Avoid height collapse animations in layouts.

8. **Auto-dismiss Timer restarts on Repeater rebuild** — Calculate remaining time from creation timestamp, not a fixed interval.

9. **Every interactive color change needs `Behavior on color`** — Icons and backgrounds that change on hover must have `Behavior on color { ColorAnimation { duration: Style.animFast } }`. Without it, the transition is jarring.

10. **Always set `fill` on MaterialIcon** — Use `fill: 1` for solid icons, `fill: 0` for outlined. Omitting it leads to inconsistent rendering.

11. **Always set `hoverEnabled: true` on hover MouseAreas** — Without this, `containsMouse` won't update on mouse movement. Only omit for click-only areas.

12. **Repeater delegate properties reset on model rebuild** — Any runtime property set on a delegate (e.g. `_userDismissed`, hover state) is lost when the model array is reassigned, because the delegate is destroyed and recreated. Never rely on delegate state surviving across model updates or timer callbacks. Instead, lift persistent state to the parent component (e.g. `hoveredPid` on the parent Item) or the singleton/manager (e.g. a tracking array).

13. **Multi-screen Variants create duplicate delegates** — Each screen gets its own PanelWindow and Repeater via `Variants { model: Quickshell.screens }`. Timers and dismiss logic fire independently per screen, causing race conditions (e.g. one screen's `finishDismiss` destroys delegates on all screens). For logic that should only run once (like history cleanup), put it in the singleton with its own Timer rather than in the delegate.

## File Structure

```
quickshell/
  shell.qml                     # Entry point
  Singleton/
    Style.qml                   # All design tokens
    PanelManager.qml            # Exclusive panel management
  common/
    StyledText.qml              # Themed text
    MaterialIcon.qml            # Material icons
    VUMeter.qml                 # Segmented bar
    CloseButton.qml             # Panel close button
    NeonStrip.qml               # Decorative accent strip
    Button.qml                  # Command button data
  modules/
    bar/
      Bar.qml                   # Main bar layout
      components/               # Bar widgets (Volume, Clock, SysMon, Media, Weather, etc.)
    volume/                     # VolumeState + VolumePanel
    calendar/                   # CalendarState + CalendarPanel
    sysmon/                     # SysMonState + SysMonPanel
    media/                      # MediaState + MediaPanel
    bluetooth/                  # BluetoothManager + BluetoothPanel
    network/                    # NetworkManager + NetworkPanel
    notifications/              # NotificationManager + popup/history
    powermenu/                  # PowerMenuState + PowerMenuPanel
    systray/                    # TrayMenuState + TrayMenuPanel
    updates/                    # UpdateState + UpdatePanel (pacman/yay)
    weather/                    # WeatherState + WeatherPanel (Open-Meteo API)
    osd/                        # Volume/toggle OSD overlay
```

## Checklist for New Widgets

- [ ] `pragma ComponentBehavior: Bound` at top
- [ ] All colors from `Style` — no hardcoded hex values
- [ ] All spacing/radii/font sizes from `Style` tokens
- [ ] Use `StyledText` and `MaterialIcon`, not raw `Text`
- [ ] `MaterialIcon` always has `fill` property set (0 or 1)
- [ ] Panel follows State singleton + PanelManager pattern
- [ ] Click-outside MouseArea on panel overlay
- [ ] Fade + slide animation on panel card
- [ ] `margins.top` for bar passthrough
- [ ] Per-monitor scale factor: `sf: modelData.height / 1080` (margins only, not `scale`)
- [ ] `NeonStrip` on panel cards
- [ ] `CloseButton` if panel needs manual close
- [ ] Hover states use `Behavior on color` with `animFast`
- [ ] All hover MouseAreas have `hoverEnabled: true`
- [ ] Clickable elements have `cursorShape: Qt.PointingHandCursor`
