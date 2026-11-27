import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: overlay
    property bool allowDragging: true
    property int opacityPercent: 100
    property bool nativeSettingsEnabled: false
    property rect settingsWorkArea: Qt.rect(Screen.virtualX, Screen.virtualY,
                                            Screen.width, Screen.height)
    readonly property alias flightWindow: flights
    signal nativeSettingsRequested()

    width: glass.implicitWidth
    height: glass.implicitHeight + 5
    color: "transparent"
    opacity: opacityPercent / 100
    title: qsTr("Key Balloons")
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus

    function showKey(label: string) {
        field.spawn(label)
        glass.pulse()
    }

    function showSettings() {
        if (nativeSettingsEnabled) {
            nativeSettingsRequested()
            return
        }

        const gap = 10
        const margin = 8
        const left = settingsWorkArea.x + margin
        const right = settingsWorkArea.x + settingsWorkArea.width - margin
        const top = settingsWorkArea.y + margin
        const bottom = settingsWorkArea.y + settingsWorkArea.height - margin
        const rightX = x + width + gap
        const leftX = x - boxMenu.width - gap
        const fitsRight = rightX + boxMenu.width <= right
        if (fitsRight || leftX >= left) {
            boxMenu.x = fitsRight ? rightX : leftX
            const centeredY = y + (height - boxMenu.height) / 2
            boxMenu.y = Math.round(Math.max(top, Math.min(centeredY, bottom - boxMenu.height)))
        } else {
            const roomAbove = y - top
            const roomBelow = bottom - (y + height)
            const centeredX = x + (width - boxMenu.width) / 2
            boxMenu.x = Math.round(Math.max(left, Math.min(centeredX, right - boxMenu.width)))
            boxMenu.y = roomAbove >= roomBelow ? y - boxMenu.height - gap : y + height + gap
        }
        boxMenu.show()
        boxMenu.requestActivate()
    }

    GlassBox {
        id: glass
        width: implicitWidth
        height: implicitHeight
        dark: field.dark

        MouseArea {
            objectName: "boxInput"
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: overlay.allowDragging ? Qt.OpenHandCursor : Qt.ArrowCursor

            onPressed: mouse => {
                if (mouse.button === Qt.LeftButton && overlay.allowDragging)
                    overlay.startSystemMove()
            }
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    overlay.showSettings()
            }
        }
    }

    Window {
        id: boxMenu
        objectName: "boxMenu"
        width: 216
        height: settingsPane.implicitHeight
        flags: Qt.Popup | Qt.FramelessWindowHint
        color: "transparent"
        onActiveChanged: if (!active) hide()

        Shortcut {
            sequence: "Escape"
            onActivated: boxMenu.hide()
        }

        Pane {
            id: settingsPane
            anchors.fill: parent
            padding: 12

            contentItem: ColumnLayout {
                spacing: 8

                Switch {
                    objectName: "draggingSwitch"
                    text: qsTr("Allow dragging")
                    checked: overlay.allowDragging
                    indicator.scale: 0.85
                    onToggled: overlay.allowDragging = checked
                }

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: qsTr("Opacity")
                        Layout.fillWidth: true
                    }
                    Label {
                        text: qsTr("%1%").arg(overlay.opacityPercent)
                    }
                }

                Slider {
                    objectName: "opacitySlider"
                    Accessible.name: qsTr("Opacity")
                    Layout.fillWidth: true
                    from: 20
                    to: 100
                    value: overlay.opacityPercent
                    stepSize: 1
                    snapMode: Slider.SnapAlways
                    onMoved: overlay.opacityPercent = Math.round(value)
                }
            }
        }
    }

    Window {
        id: flights
        transientParent: overlay
        width: 360
        height: 265
        x: overlay.x + (overlay.width - width) / 2
        y: Math.round(overlay.y + glass.mouthY - height)
        color: "transparent"
        opacity: overlay.opacity
        flags: overlay.flags | Qt.WindowTransparentForInput
        visible: overlay.visible

        BalloonField {
            id: field
            anchors.fill: parent
        }
    }
}
