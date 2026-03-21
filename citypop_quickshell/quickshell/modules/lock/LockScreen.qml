pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../Singleton"
import "../../common"

Scope {
    id: root

    property bool locked: false
    property string password: ""
    property bool authFailed: false
    property bool authenticating: false

    function lock() {
        locked = true
        password = ""
        authFailed = false
    }

    function tryUnlock() {
        if (authenticating || password === "") return
        authenticating = true
        authProc.command = ["sh", "-c",
            "echo '" + password.replace(/'/g, "'\\''") + "' | su -c 'exit' " + root.userName + " 2>/dev/null"
        ]
        authProc.running = true
    }

    property string userName: ""

    Process {
        id: userProc
        command: ["whoami"]
        running: true

        stdout: SplitParser {
            onRead: data => root.userName = data
        }
    }

    Process {
        id: authProc

        onExited: (exitCode, exitStatus) => {
            root.authenticating = false
            if (exitCode === 0) {
                root.locked = false
                root.password = ""
            } else {
                root.authFailed = true
                root.password = ""
                shakeAnim.start()
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.locked
            color: Style.bgPrimary

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusionMode: ExclusionMode.Ignore

            // Gradient overlay
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0.1, 0.04, 0.18, 0.8) }
                    GradientStop { position: 0.5; color: Qt.rgba(0.17, 0.11, 0.24, 0.6) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.1, 0.04, 0.18, 0.9) }
                }
            }

            // Centered lock content
            ColumnLayout {
                id: lockContent
                anchors.centerIn: parent
                spacing: Style.spaceXl
                width: 320

                // Clock
                StyledText {
                    text: Time.time
                    font.pixelSize: 48
                    font.bold: true
                    color: Style.accentPink
                    Layout.alignment: Qt.AlignHCenter
                }

                StyledText {
                    text: Time.date
                    font.pixelSize: Style.fontSizeLg
                    color: Style.textSecondary
                    Layout.alignment: Qt.AlignHCenter
                }

                Item { implicitHeight: Style.spaceXl }

                // Password field
                Rectangle {
                    id: passwordBox
                    Layout.fillWidth: true
                    height: 44
                    radius: Style.radiusMd
                    color: Style.bgSecondary
                    border.width: 2
                    border.color: root.authFailed ? Style.colorUrgent : Style.accentPink

                    Behavior on border.color {
                        ColorAnimation { duration: Style.animNormal }
                    }

                    NumberAnimation {
                        id: shakeAnim
                        target: passwordBox
                        property: "x"
                        from: passwordBox.x - 10
                        to: passwordBox.x + 10
                        duration: 80
                        loops: 3
                        easing.type: Easing.InOutQuad
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Style.spaceMd
                        spacing: Style.spaceMd

                        MaterialIcon {
                            text: "lock"
                            font.pixelSize: 20
                            color: Style.accentPink
                        }

                        TextInput {
                            id: passwordInput
                            Layout.fillWidth: true
                            color: Style.textPrimary
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontSizeMd
                            echoMode: TextInput.Password
                            clip: true
                            focus: root.locked

                            onTextChanged: {
                                root.password = text
                                root.authFailed = false
                            }

                            Keys.onReturnPressed: root.tryUnlock()
                        }
                    }
                }

                StyledText {
                    text: root.authenticating ? "Authenticating..." : root.authFailed ? "Wrong password" : ""
                    color: root.authFailed ? Style.colorUrgent : Style.textSecondary
                    font.pixelSize: Style.fontSizeSm
                    Layout.alignment: Qt.AlignHCenter
                    visible: text !== ""
                }
            }
        }
    }
}
