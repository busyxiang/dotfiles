# City Pop Quickshell

A desktop shell for [Quickshell](https://quickshell.outfoxxed.me/) on Hyprland with an 80s Japanese city pop neon aesthetic.

## Screenshot

<!-- TODO: add screenshot -->

## Dependencies

- [Quickshell](https://quickshell.outfoxxed.me/) (Wayland compositor shell)
- [Hyprland](https://hyprland.org/) (Wayland compositor)
- [CaskaydiaCove Nerd Font](https://www.nerdfonts.com/)
- [Material Symbols Rounded](https://fonts.google.com/icons) (icon font)
- [PipeWire](https://pipewire.org/) (audio)
- [NetworkManager](https://networkmanager.dev/) / `nmcli` (networking)
- [bluetoothctl](https://wiki.archlinux.org/title/Bluetooth) (bluetooth)
- [fcitx5](https://fcitx-im.org/) (input method, optional)
- `wl-copy` (clipboard, for calendar date copy)

## Structure

```
quickshell/
├── shell.qml                    # Entry point
├── Singleton/
│   ├── Style.qml                # Theme tokens (colors, spacing, radii, fonts, animations)
│   ├── PanelManager.qml         # Exclusive panel open/close management
│   └── Time.qml                 # Clock data provider
├── common/                      # Reusable components
│   ├── Button.qml               # Command executor button
│   ├── CloseButton.qml          # 28x28 panel close button with hover
│   ├── MaterialIcon.qml         # Material Symbols icon wrapper
│   ├── NeonStrip.qml            # 2px neon accent strip for panel tops
│   ├── StyledText.qml           # Themed text with default font/color
│   └── VUMeter.qml              # Segmented meter with threshold coloring
└── modules/
    ├── bar/
    │   ├── Bar.qml              # Main bar layout (left / center / right)
    │   └── components/
    │       ├── Workspaces.qml   # Hyprland workspace pills
    │       ├── WindowTitle.qml  # Active window title + app icon
    │       ├── SysMon.qml       # CPU/GPU/RAM compact pills
    │       ├── NetStat.qml      # Upload/download speed pill
    │       ├── Media.qml        # MPRIS controls + spinning vinyl
    │       ├── SysTray.qml      # System tray icons
    │       ├── Bluetooth.qml    # BT status + device count badge
    │       ├── Volume.qml       # Volume icon with overdrive colors
    │       ├── Network.qml      # Wifi signal bars / ethernet icon
    │       ├── Keyboard.qml     # Input method indicator (fcitx5)
    │       ├── NotificationButton.qml  # Bell icon + unread badge
    │       ├── Weather.qml      # Weather icon + temperature (Open-Meteo)
    │       ├── Updates.qml      # Package update count badge (pacman/yay)
    │       ├── Clock.qml        # Neon clock with pulsing colons
    │       └── PowerMenu.qml    # Power icon with danger glow
    ├── bluetooth/               # BT panel (scan, connect, pair, forget)
    ├── calendar/                # Calendar dropdown with month navigation
    ├── media/                   # Media panel (album art, seek bar, player switcher)
    ├── network/                 # Wifi panel (scan, connect, password input)
    ├── notifications/           # Notification daemon, popups, history panel
    ├── osd/                     # On-screen display (volume, caps/num lock)
    ├── powermenu/               # Power menu (lock, logout, reboot, shutdown)
    ├── sysmon/                  # System monitor panel (VU meters, process table)
    ├── systray/                 # Custom themed tray context menus
    ├── updates/                 # Update checker panel (pacman + AUR, retry with backoff)
    ├── volume/                  # Volume panel (output/input VU meters, app mixer, device switching)
    └── weather/                 # Weather panel (Open-Meteo API, multi-location, retry with backoff)
```

## Bar Layout

```
[Updates] [Workspaces] [WindowTitle] [SysMon] [NetStat] ... [Media] ... [Tray] [BT] [Vol] [Net] [KB] [Notif] [Weather] [Clock] [Power]
```

## Color Palette

| Token | Color | Usage |
|-------|-------|-------|
| `bgPrimary` | `#1a0a2e` | Deep night purple background |
| `bgSecondary` | `#2b1b3d` | Raised surfaces, panels |
| `bgTertiary` | `#3d2b4f` | Hover states, unlit segments |
| `accentPink` | `#ff69b4` | Primary accent, VU meter base |
| `accentMagenta` | `#ff1493` | Deep pink emphasis |
| `accentAmber` | `#ffb347` | Warning states, overdrive 100-130% |
| `accentPurple` | `#da70d6` | Input/RAM accent |
| `colorUrgent` | `#ff4466` | Critical states, overdrive 130%+ |
| `colorGood` | `#66bb6a` | Temperature normal, input level |
| `textPrimary` | `#f0e6f6` | Warm lavender-white |
| `textSecondary` | `#b8a9c9` | Muted text |
| `textDimmed` | `#6b5b7b` | Inactive/disabled |

## VUMeter Component

The `VUMeter` component is used throughout for volume sliders, CPU/GPU/RAM bars, seek bars, and OSD displays.

```qml
VUMeter {
    segments: 20        // number of segments
    value: 0.75         // 0.0 – 1.0 normalized
    muted: false        // all segments dim when true
    baseColor: Style.accentPink
    warnAt: 0.7         // fraction where amber starts
    critAt: 0.9         // fraction where red starts
}
```

## External Tools

These features are handled by external programs rather than Quickshell:

- **App Launcher** — [hyprlauncher](https://github.com/hyprutils/hyprlauncher)
- **Session Lock** — [hyprlock](https://github.com/hyprwm/hyprlock)
- **Wallpaper** — [hyprpaper](https://github.com/hyprwm/hyprpaper)

## References

- [Quickshell Documentation](https://quickshell.outfoxxed.me/)
- [Qt QML Text](https://doc.qt.io/qt-6/qml-qtquick-text.html)
- [Material Symbols](https://fonts.google.com/icons)
