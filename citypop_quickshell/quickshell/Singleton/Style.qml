pragma Singleton

import Quickshell

Singleton {
    // === Background Colors ===
    readonly property string bgPrimary: "#1a0a2e"
    readonly property string bgSecondary: "#2b1b3d"
    readonly property string bgTertiary: "#3d2b4f"
    readonly property string bgBar: "#1a0a2e"

    // === Accent Colors ===
    readonly property string accentPink: "#ff69b4"
    readonly property string accentMagenta: "#ff1493"
    readonly property string accentAmber: "#ffb347"
    readonly property string accentPurple: "#da70d6"

    // === Text Colors ===
    readonly property string textPrimary: "#f0e6f6"
    readonly property string textSecondary: "#b8a9c9"
    readonly property string textDimmed: "#6b5b7b"

    // === Semantic Colors ===
    readonly property string colorActive: "#ff69b4"
    readonly property string colorInactive: "#6b5b7b"
    readonly property string colorUrgent: "#ff4466"

    // === Spacing Scale (px) ===
    readonly property int spaceXs: 2
    readonly property int spaceSm: 4
    readonly property int spaceMd: 8
    readonly property int spaceLg: 12
    readonly property int spaceXl: 16

    // === Bar Dimensions ===
    readonly property int barHeight: 36
    readonly property int barPadding: 8

    // === Border Radii ===
    readonly property int radiusSm: 4
    readonly property int radiusMd: 8
    readonly property int radiusLg: 12
    readonly property int radiusFull: 999

    // === Font ===
    readonly property string fontFamily: "CaskaydiaCove Nerd Font"
    readonly property string iconFontFamily: "Material Symbols Rounded"
    readonly property int fontSizeSm: 13
    readonly property int fontSizeMd: 15
    readonly property int fontSizeLg: 17
    readonly property int fontSizeXl: 20

    // === Animation ===
    readonly property int animFast: 120
    readonly property int animNormal: 200
    readonly property int animSlow: 350
}
