import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: overlay
    property bool allowDragging: true
    property var preferences: null
    property bool autoSnapToBottom: preferences ? preferences.autoSnapToBottom : false
    readonly property alias snapDragInProgress: boxInput.snapDragInProgress
    property int opacityPercent: 100
    property int sizePercent: 100
    readonly property int minimumSizePercent: 50
    readonly property int maximumSizePercent: 150
    readonly property real sizeFactor: sizePercent / 100
    property bool nativeSettingsEnabled: false
    property rect settingsWorkArea: Qt.rect(Screen.virtualX, Screen.virtualY,
                                            Screen.width, Screen.height)
    readonly property alias flightWindow: flights
    signal nativeSettingsRequested()
    signal snapToBottomRequested()

    width: Math.round(glass.implicitWidth * sizeFactor)
    height: Math.round((glass.implicitHeight + 5) * sizeFactor)
    color: "transparent"
    opacity: opacityPercent / 100
    title: qsTr("Key Balloons")
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    onSizePercentChanged: Qt.callLater(keepBoxOnScreen)

    function keepBoxOnScreen() {
        if (autoSnapToBottom) {
            if (!snapDragInProgress)
                snapToBottomRequested()
            return
        }
        const area = settingsWorkArea
        x = Math.max(area.x, Math.min(x, area.x + area.width - width))
        y = Math.max(area.y, Math.min(y, area.y + area.height - height))
    }

    function showKey(label: string) {
        field.spawn(label)
        glass.pulse()
    }

    function showMouseFeedback(event: string) {
        glass.mousePulse(event)
    }

    function showSettings() {
        if (nativeSettingsEnabled) {
            nativeSettingsRequested()
            return
        }

        positionSettings()
        boxMenu.show()
        boxMenu.requestActivate()
        settingsPane.forceActiveFocus(Qt.PopupFocusReason)
    }

    function positionSettings() {
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
            const preferredY = roomAbove >= roomBelow ? y - boxMenu.height - gap : y + height + gap
            boxMenu.y = Math.round(Math.max(top, Math.min(preferredY, bottom - boxMenu.height)))
        }
    }

    GlassBox {
        id: glass
        width: implicitWidth
        height: implicitHeight
        scale: overlay.sizeFactor
        transformOrigin: Item.TopLeft
        dark: field.dark

        MouseArea {
            id: boxInput
            objectName: "boxInput"
            property bool snapDragInProgress: false
            property point dragOffset
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: overlay.allowDragging ? Qt.OpenHandCursor : Qt.ArrowCursor

            onPressed: mouse => {
                if (mouse.button !== Qt.LeftButton || !overlay.allowDragging)
                    return
                if (overlay.autoSnapToBottom) {
                    const point = mapToGlobal(mouse.x, mouse.y)
                    dragOffset = Qt.point(point.x - overlay.x, point.y - overlay.y)
                    snapDragInProgress = true
                } else {
                    overlay.startSystemMove()
                }
            }
            onPositionChanged: mouse => {
                if (!snapDragInProgress)
                    return
                const point = mapToGlobal(mouse.x, mouse.y)
                overlay.x = Math.round(point.x - dragOffset.x)
                overlay.y = Math.round(point.y - dragOffset.y)
            }
            onReleased: mouse => {
                if (mouse.button === Qt.LeftButton)
                    finishSnapDrag()
            }
            onCanceled: finishSnapDrag()
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    overlay.showSettings()
            }

            function finishSnapDrag() {
                if (!snapDragInProgress)
                    return
                snapDragInProgress = false
                overlay.snapToBottomRequested()
            }
        }
    }

    Window {
        id: boxMenu
        objectName: "boxMenu"
        width: 310
        height: settingsPane.implicitHeight
        flags: Qt.Popup | Qt.FramelessWindowHint
        color: "transparent"
        onActiveChanged: if (!active) hide()
        onHeightChanged: if (visible) overlay.positionSettings()
        onVisibleChanged: if (!visible) settingsPane.advancedExpanded = false

        Pane {
            id: settingsPane
            objectName: "settingsPane"
            anchors.fill: parent
            padding: 14
            property bool advancedExpanded: false
            Keys.onEscapePressed: boxMenu.hide()

            contentItem: ColumnLayout {
                spacing: 8

                Label {
                    text: qsTr("Appearance")
                    font.weight: Font.DemiBold
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

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: qsTr("Size")
                        Layout.fillWidth: true
                    }
                    Label {
                        text: qsTr("%1%").arg(overlay.sizePercent)
                    }
                }

                Slider {
                    objectName: "sizeSlider"
                    Accessible.name: qsTr("Size")
                    Layout.fillWidth: true
                    from: overlay.minimumSizePercent
                    to: overlay.maximumSizePercent
                    value: overlay.sizePercent
                    stepSize: 1
                    snapMode: Slider.SnapAlways
                    onMoved: overlay.sizePercent = Math.round(value)
                }

                Label {
                    text: qsTr("Position")
                    font.weight: Font.DemiBold
                }

                Switch {
                    objectName: "draggingSwitch"
                    text: qsTr("Allow dragging")
                    checked: overlay.allowDragging
                    indicator.scale: 0.85
                    onToggled: overlay.allowDragging = checked
                }

                Switch {
                    objectName: "snapSwitch"
                    text: qsTr("Snap box to screen bottom")
                    checked: overlay.autoSnapToBottom
                    enabled: !!overlay.preferences
                    indicator.scale: 0.85
                    onToggled: overlay.preferences.autoSnapToBottom = checked
                }

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: qsTr("Language")
                        Layout.fillWidth: true
                    }
                    ComboBox {
                        objectName: "languageCombo"
                        Accessible.name: qsTr("Language")
                        model: overlay.preferences ? overlay.preferences.languages : []
                        textRole: "label"
                        valueRole: "code"
                        currentValue: overlay.preferences ? overlay.preferences.language : ""
                        onActivated: index => overlay.preferences.language = valueAt(index)
                    }
                }

                ToolButton {
                    objectName: "advancedButton"
                    text: (settingsPane.advancedExpanded ? "▾ " : "▸ ") + qsTr("Advanced")
                    Accessible.name: qsTr("Advanced")
                    onClicked: settingsPane.advancedExpanded = !settingsPane.advancedExpanded
                }

                Switch {
                    objectName: "integrationsSwitch"
                    text: qsTr("Allow local mouse integrations")
                    visible: settingsPane.advancedExpanded
                    enabled: overlay.preferences ? overlay.preferences.integrationsAvailable : false
                    checked: overlay.preferences ? overlay.preferences.integrationsEnabled : false
                    indicator.scale: 0.85
                    onToggled: overlay.preferences.integrationsEnabled = checked
                }
            }
        }
    }

    Window {
        id: flights
        transientParent: overlay
        width: Math.round(field.width * overlay.sizeFactor)
        height: Math.round(field.height * overlay.sizeFactor)
        x: Math.round(overlay.x + (overlay.width - width) / 2)
        y: Math.round(overlay.y + glass.mouthY * overlay.sizeFactor - height)
        color: "transparent"
        opacity: overlay.opacity
        flags: overlay.flags | Qt.WindowTransparentForInput
        visible: overlay.visible

        BalloonField {
            id: field
            width: 360
            height: 265
            x: (parent.width - width) / 2
            y: parent.height - height
            scale: overlay.sizeFactor
            transformOrigin: Item.Bottom
        }
    }
}
