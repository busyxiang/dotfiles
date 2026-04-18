pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../Singleton"

PanelWindow {
    id: root

    // ── State bindings (required) ──
    property bool stateOpen: false
    property var stateScreen: null
    signal dismissed()

    // ── Derived ──
    readonly property real sf: root.screen ? root.screen.height / 1080 : 1
    readonly property bool isOpen: stateOpen && stateScreen === root.screen

    // ── Card geometry ──
    property int cardWidth: 360
    property int cardHeight: -1
    property real cardPadding: Style.spaceXl

    // ── Card anchoring: "top-right" | "top-left" | "top-center" | "widget" ──
    property string anchorMode: "top-right"
    property real anchorTopMargin: Style.spaceMd
    property real anchorRightMargin: Style.spaceMd
    property real anchorLeftMargin: Style.spaceMd
    // For "widget" mode: X coordinate of the bar widget center (screen-relative)
    property real widgetCenterX: 0

    // ── Card appearance ──
    property bool showNeonStrip: true
    property bool cardClip: false
    property color cardColor: Style.bgSecondary
    property real cardRadius: Style.radiusLg
    property color cardBorderColor: Style.bgTertiary

    // ── Expose active card for external anchoring ──
    readonly property Rectangle card: _activeCard

    // ── Content ──
    default property alias cardContent: _contentArea.data

    // ── PanelWindow setup ──
    visible: root.isOpen || _activeCard.opacity > 0
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    margins.top: Math.round(Style.barHeight * root.sf)

    // ── Click outside to dismiss ──
    MouseArea {
        anchors.fill: parent
        enabled: root.isOpen
        onClicked: root.dismissed()
    }

    // ── Top-right card ──
    Rectangle {
        id: _cardTopRight
        visible: root.anchorMode === "top-right"
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Math.round(root.anchorTopMargin * root.sf)
        anchors.rightMargin: Math.round(root.anchorRightMargin * root.sf)
        width: root.cardWidth
        height: _cardHeight
        color: root.cardColor; radius: root.cardRadius
        border.width: 1; border.color: root.cardBorderColor; clip: root.cardClip
        opacity: root.isOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
        transform: Translate { y: root.isOpen ? 0 : -8; Behavior on y { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } } }
    }

    // ── Top-left card ──
    Rectangle {
        id: _cardTopLeft
        visible: root.anchorMode === "top-left"
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: Math.round(root.anchorTopMargin * root.sf)
        anchors.leftMargin: Math.round(root.anchorLeftMargin * root.sf)
        width: root.cardWidth
        height: _cardHeight
        color: root.cardColor; radius: root.cardRadius
        border.width: 1; border.color: root.cardBorderColor; clip: root.cardClip
        opacity: root.isOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
        transform: Translate { y: root.isOpen ? 0 : -8; Behavior on y { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } } }
    }

    // ── Top-center card ──
    Rectangle {
        id: _cardTopCenter
        visible: root.anchorMode === "top-center"
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Math.round(root.anchorTopMargin * root.sf)
        width: root.cardWidth
        height: _cardHeight
        color: root.cardColor; radius: root.cardRadius
        border.width: 1; border.color: root.cardBorderColor; clip: root.cardClip
        opacity: root.isOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
        transform: Translate { y: root.isOpen ? 0 : -8; Behavior on y { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } } }
    }

    // ── Widget-aligned card ──
    Rectangle {
        id: _cardWidget
        visible: root.anchorMode === "widget"
        y: Math.round(root.anchorTopMargin * root.sf)
        x: Math.max(Math.round(Style.spaceMd * root.sf),
           Math.min(root.widgetCenterX - width / 2,
                    root.width - width - Math.round(Style.spaceMd * root.sf)))
        width: root.cardWidth
        height: _cardHeight
        color: root.cardColor; radius: root.cardRadius
        border.width: 1; border.color: root.cardBorderColor; clip: root.cardClip
        opacity: root.isOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } }
        transform: Translate { y: root.isOpen ? 0 : -8; Behavior on y { NumberAnimation { duration: Style.animNormal; easing.type: Easing.OutCubic } } }
    }

    // ── Shared card height ──
    readonly property real _cardHeight: root.cardHeight >= 0 ? root.cardHeight
          : (_contentArea.implicitHeight + root.cardPadding * 2)

    // ── Active card reference ──
    readonly property Rectangle _activeCard: root.anchorMode === "top-left" ? _cardTopLeft
                                           : root.anchorMode === "top-center" ? _cardTopCenter
                                           : root.anchorMode === "widget" ? _cardWidget
                                           : _cardTopRight

    // ── NeonStrip on active card ──
    NeonStrip { parent: root._activeCard; visible: root.showNeonStrip }

    // ── Block click-through on active card ──
    MouseArea { parent: root._activeCard; anchors.fill: parent; z: 0 }

    // ── Content container on active card ──
    Item {
        id: _contentArea
        parent: root._activeCard
        z: 1
        anchors.fill: parent
        anchors.margins: root.cardPadding
        implicitHeight: children.length > 0 ? children[0].implicitHeight : 0
        implicitWidth: children.length > 0 ? children[0].implicitWidth : 0
    }
}
