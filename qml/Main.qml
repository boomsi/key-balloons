import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: overlay
    readonly property alias allowDragging: dragCheck.checked
    readonly property alias flightWindow: flights

    width: glass.implicitWidth
    height: glass.implicitHeight + 5
    color: "transparent"
    opacity: opacitySlider.value / 100
    title: qsTr("Key Balloons")
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus

    function showKey(label: string) {
        field.spawn(label)
        glass.pulse()
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
                if (mouse.button === Qt.RightButton) {
                    boxMenu.x = mouse.x
                    boxMenu.y = mouse.y
                    boxMenu.open()
                }
            }
        }
    }

    Popup {
        id: boxMenu
        objectName: "boxMenu"
        parent: glass
        popupType: Popup.Window
        width: 216
        margins: 8
        padding: 12
        focus: true

        contentItem: ColumnLayout {
            spacing: 8

            CheckBox {
                id: dragCheck
                objectName: "allowDraggingCheck"
                text: qsTr("Allow dragging")
                checked: true
                onClicked: boxMenu.close()
            }

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: qsTr("Opacity")
                    Layout.fillWidth: true
                }
                Label {
                    text: qsTr("%1%").arg(opacitySlider.value.toFixed(0))
                }
            }

            Slider {
                id: opacitySlider
                objectName: "opacitySlider"
                Accessible.name: qsTr("Opacity")
                Layout.fillWidth: true
                from: 20
                to: 100
                value: 100
                stepSize: 1
                snapMode: Slider.SnapAlways
            }
        }
    }

    Window {
        id: flights
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
