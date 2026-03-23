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
    readonly property string colorGood: "#66bb6a"

    // === Derived Alpha Colors (common hover/border/gradient tints) ===
    readonly property string pinkHover: "#1aff69b4"       // accentPink @ 10%
    readonly property string pinkBorder: "#4dff69b4"      // accentPink @ 30%
    readonly property string pinkGradientStart: "#1fff69b4" // accentPink @ 12%
    readonly property string pinkGradientEnd: "#0aff69b4"  // accentPink @ 4%

    readonly property string urgentHover: "#26ff4466"     // colorUrgent @ 15%
    readonly property string urgentBg: "#1aff4466"        // colorUrgent @ 10%
    readonly property string urgentBgStrong: "#40ff4466"  // colorUrgent @ 25%
    readonly property string urgentBorder: "#4dff4466"    // colorUrgent @ 30%
    readonly property string urgentGlow: "#66ff4466"      // colorUrgent @ 40%

    readonly property string amberBg: "#1affb347"         // accentAmber @ 10%
    readonly property string amberBorder: "#4dffb347"     // accentAmber @ 30%
    readonly property string amberGlow: "#66ffb347"       // accentAmber @ 40%

    readonly property string purpleHover: "#1ada70d6"     // accentPurple @ 10%

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
