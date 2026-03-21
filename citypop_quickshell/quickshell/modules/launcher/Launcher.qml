pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../Singleton"
import "../../common"

Scope {
    id: root

    property bool visible: false
    property string searchQuery: ""
    property list<var> allApps: []
    property list<var> filteredApps: []
    property int selectedIndex: 0

    function toggle() {
        visible = !visible
        if (visible) {
            searchQuery = ""
            selectedIndex = 0
            loadApps()
        }
    }

    function loadApps() {
        appListProc.running = true
    }

    function filterApps() {
        if (searchQuery === "") {
            filteredApps = allApps.slice(0, 30)
        } else {
            var query = searchQuery.toLowerCase()
            filteredApps = allApps.filter(app => {
                return app.name.toLowerCase().indexOf(query) >= 0 ||
                       (app.comment && app.comment.toLowerCase().indexOf(query) >= 0)
            }).slice(0, 30)
        }
        selectedIndex = 0
    }

    function launchSelected() {
        if (filteredApps.length > 0 && selectedIndex < filteredApps.length) {
            launchProc.command = ["sh", "-c", filteredApps[selectedIndex].exec]
            launchProc.startDetached()
            visible = false
        }
    }

    onSearchQueryChanged: filterApps()

    Process {
        id: appListProc
        command: ["sh", "-c", "find /usr/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null | head -200"]

        stdout: SplitParser {
            onRead: data => {
                desktopParser.command = ["sh", "-c",
                    "grep -m1 '^Name=' '" + data + "' | cut -d= -f2; " +
                    "grep -m1 '^Exec=' '" + data + "' | cut -d= -f2 | sed 's/ %[fFuUdDnNickvm]//g'; " +
                    "grep -m1 '^Comment=' '" + data + "' | cut -d= -f2; " +
                    "grep -m1 '^Icon=' '" + data + "' | cut -d= -f2"
                ]
                desktopParser.running = true
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.filterApps()
        }
    }

    Process {
        id: desktopParser

        property string name: ""
        property string exec_: ""
        property string comment: ""
        property string icon: ""
        property int lineNum: 0

        stdout: SplitParser {
            onRead: data => {
                switch (desktopParser.lineNum) {
                    case 0: desktopParser.name = data; break
                    case 1: desktopParser.exec_ = data; break
                    case 2: desktopParser.comment = data; break
                    case 3: desktopParser.icon = data; break
                }
                desktopParser.lineNum++
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (desktopParser.name && desktopParser.exec_) {
                var copy = root.allApps.slice()
                copy.push({
                    name: desktopParser.name,
                    exec: desktopParser.exec_,
                    comment: desktopParser.comment,
                    icon: desktopParser.icon
                })
                root.allApps = copy
            }
            desktopParser.name = ""
            desktopParser.exec_ = ""
            desktopParser.comment = ""
            desktopParser.icon = ""
            desktopParser.lineNum = 0
        }
    }

    Process { id: launchProc }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.visible
            color: Qt.rgba(0, 0, 0, 0.6)

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore

            // Click outside to close
            MouseArea {
                anchors.fill: parent
                onClicked: root.visible = false
            }

            // Centered launcher box
            Rectangle {
                anchors.centerIn: parent
                width: 500
                height: 460
                radius: Style.radiusLg
                color: Style.bgPrimary
                border.width: 1
                border.color: Style.bgTertiary

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Style.spaceXl
                    spacing: Style.spaceLg

                    // Search input
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: Style.radiusMd
                        color: Style.bgSecondary
                        border.width: 1
                        border.color: searchInput.activeFocus ? Style.accentPink : Style.bgTertiary

                        Behavior on border.color {
                            ColorAnimation { duration: Style.animFast }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Style.spaceMd
                            spacing: Style.spaceMd

                            MaterialIcon {
                                text: "search"
                                font.pixelSize: 20
                                color: Style.accentPink
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                color: Style.textPrimary
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontSizeMd
                                clip: true
                                focus: root.visible

                                onTextChanged: root.searchQuery = text

                                Keys.onUpPressed: {
                                    if (root.selectedIndex > 0)
                                        root.selectedIndex--
                                }

                                Keys.onDownPressed: {
                                    if (root.selectedIndex < root.filteredApps.length - 1)
                                        root.selectedIndex++
                                }

                                Keys.onReturnPressed: root.launchSelected()
                                Keys.onEscapePressed: root.visible = false

                                StyledText {
                                    anchors.fill: parent
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Search apps..."
                                    color: Style.textDimmed
                                    visible: !searchInput.text && !searchInput.activeFocus
                                }
                            }
                        }
                    }

                    // App list
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: Style.spaceXs
                        model: root.filteredApps
                        currentIndex: root.selectedIndex

                        delegate: Rectangle {
                            id: appItem
                            required property var modelData
                            required property int index

                            width: ListView.view.width
                            height: 44
                            radius: Style.radiusSm
                            color: index === root.selectedIndex ? Style.bgTertiary
                                 : itemMouse.containsMouse ? Style.bgSecondary
                                 : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: Style.animFast }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Style.spaceMd
                                spacing: Style.spaceMd

                                MaterialIcon {
                                    text: "apps"
                                    font.pixelSize: 20
                                    color: appItem.index === root.selectedIndex ? Style.accentAmber : Style.accentPink
                                }

                                ColumnLayout {
                                    spacing: 0
                                    Layout.fillWidth: true

                                    StyledText {
                                        text: appItem.modelData.name
                                        font.pixelSize: Style.fontSizeMd
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    StyledText {
                                        text: appItem.modelData.comment || ""
                                        color: Style.textDimmed
                                        font.pixelSize: Style.fontSizeSm
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                    }
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedIndex = appItem.index
                                    root.launchSelected()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
