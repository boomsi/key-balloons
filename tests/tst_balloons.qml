import QtQuick
import QtTest
import "../qml" as Ui

TestCase {
    id: testCase
    name: "Balloons"
    width: 360
    height: 320
    visible: true
    when: windowShown

    Component {
        id: fieldComponent
        Ui.BalloonField {
            width: 360
            height: 320
        }
    }

    Component {
        id: overlayComponent
        Ui.Main {
            property int moveRequests: 0

            function startSystemMove() {
                moveRequests++
            }
        }
    }

    Component {
        id: focusTargetComponent
        Window {
            width: 120
            height: 80
        }
    }

    function test_boxDragMenuLocksAndUnlocks() {
        const overlay = createTemporaryObject(overlayComponent, null, { visible: true })
        verify(overlay)
        compare(overlay.allowDragging, true)
        const box = findChild(overlay, "boxInput")
        const menu = findChild(overlay, "boxMenu")
        const dragSwitch = findChild(overlay, "draggingSwitch")
        verify(box)
        verify(menu)
        verify(dragSwitch)

        mouseClick(box)
        compare(overlay.moveRequests, 1)

        mouseClick(box, box.width / 2, box.height / 2, Qt.RightButton)
        tryCompare(menu, "visible", true)
        compare(dragSwitch.checked, true)
        mouseClick(dragSwitch)
        compare(overlay.allowDragging, false)
        verify(menu.visible, "Locking the box should leave the settings open")
        menu.close()
        mouseClick(box)
        compare(overlay.moveRequests, 1)

        mouseClick(box, box.width / 2, box.height / 2, Qt.RightButton)
        tryCompare(menu, "visible", true)
        compare(dragSwitch.checked, false)
        mouseClick(dragSwitch)
        compare(overlay.allowDragging, true)
        compare(dragSwitch.checked, true)
        verify(menu.visible, "Unlocking the box should leave the settings open")
        menu.close()
        mouseClick(box)
        compare(overlay.moveRequests, 2)
    }

    function test_opacitySliderUpdatesBothWindows() {
        const overlay = createTemporaryObject(overlayComponent, null, { visible: true })
        verify(overlay)
        const box = findChild(overlay, "boxInput")
        const menu = findChild(overlay, "boxMenu")
        const slider = findChild(overlay, "opacitySlider")
        verify(slider)

        mouseClick(box, box.width / 2, box.height / 2, Qt.RightButton)
        tryCompare(menu, "visible", true)
        compare(slider.value, 100)
        const start = slider.mapFromItem(slider.handle, slider.handle.width / 2,
                                        slider.handle.height / 2)
        mouseDrag(slider, start.x, start.y, -slider.width / 2, 0)

        verify(slider.value < 100)
        fuzzyCompare(overlay.opacity, slider.value / 100, 0.01)
        fuzzyCompare(overlay.flightWindow.opacity, overlay.opacity, 0.01)
        menu.close()
        fuzzyCompare(overlay.opacity, slider.value / 100, 0.01)
    }

    function test_balloonWindowFollowsBox() {
        const overlay = createTemporaryObject(overlayComponent, null)
        verify(overlay)
        const flight = overlay.flightWindow
        verify(flight)
        compare(flight.transientParent, overlay)
        verify((flight.flags & Qt.WindowTransparentForInput) !== 0)
        verify((overlay.flags & Qt.WindowTransparentForInput) === 0)

        const relativeY = flight.y - overlay.y
        overlay.x = 300
        overlay.y = 400
        compare(flight.x + flight.width / 2, overlay.x + overlay.width / 2)
        compare(flight.y - overlay.y, relativeY)
    }

    function test_settingsOpenBesideBox() {
        const overlay = createTemporaryObject(overlayComponent, null, {
            x: 300, y: 300, visible: true, settingsWorkArea: Qt.rect(0, 0, 800, 600)
        })
        const box = findChild(overlay, "boxInput")
        const menu = findChild(overlay, "boxMenu")
        mouseClick(box, box.width / 2, box.height / 2, Qt.RightButton)
        tryCompare(menu, "visible", true)
        verify(menu.x >= overlay.x + overlay.width, "Right popup x=" + menu.x + ", box x=" + overlay.x
               + ", box width=" + overlay.width + ", screen width=" + overlay.screen.width)
        menu.close()
        tryCompare(menu, "visible", false)

        overlay.x = 800 - overlay.width - 20
        mouseClick(box, box.width / 2, box.height / 2, Qt.RightButton)
        tryCompare(menu, "visible", true)
        verify(menu.x + menu.width <= overlay.x, "Left popup x=" + menu.x + ", width=" + menu.width)
    }

    function test_settingsCloseOnFocusLoss() {
        const overlay = createTemporaryObject(overlayComponent, null, { visible: true })
        const box = findChild(overlay, "boxInput")
        const menu = findChild(overlay, "boxMenu")
        mouseClick(box, box.width / 2, box.height / 2, Qt.RightButton)
        tryCompare(menu, "visible", true)
        tryCompare(menu, "active", true)

        const focusTarget = createTemporaryObject(focusTargetComponent, null, { visible: true })
        focusTarget.requestActivate()
        tryCompare(focusTarget, "active", true)
        tryCompare(menu, "visible", false)
        verify(overlay.visible)
    }

    function test_settingsFocusFirstControlAndCloseOnEscape() {
        const overlay = createTemporaryObject(overlayComponent, null, { visible: true })
        const box = findChild(overlay, "boxInput")
        const menu = findChild(overlay, "boxMenu")
        const dragSwitch = findChild(overlay, "draggingSwitch")
        mouseClick(box, box.width / 2, box.height / 2, Qt.RightButton)
        tryCompare(dragSwitch, "activeFocus", true)
        keyClick(Qt.Key_Escape)
        tryCompare(menu, "visible", false)
    }

    function test_appendRepeatedLabels() {
        const field = createTemporaryObject(fieldComponent, testCase)
        const first = field.spawn("A")
        const second = field.spawn("A")
        const third = field.spawn("B")

        compare(field.activeBalloonCount, 3)
        verify(first !== second)
        verify(second !== third)
        compare(first.label, "A")
        compare(second.label, "A")
        compare(third.label, "B")
    }

    function test_balloonOnlyDrawsOutlinedText() {
        const field = createTemporaryObject(fieldComponent, testCase)
        const balloon = field.spawn("Space")
        compare(balloon.children.length, 1)
        const caption = balloon.children[0]
        compare(caption.text, "Space")
        compare(caption.style, Text.Outline)
    }

    function test_eachBalloonExpiresIndependently() {
        const field = createTemporaryObject(fieldComponent, testCase,
                                            { lifetimeMs: 900 })
        field.spawn("A")
        wait(400)
        field.spawn("B")

        compare(field.activeBalloonCount, 2)
        tryCompare(field, "activeBalloonCount", 1, 900)
        tryCompare(field, "activeBalloonCount", 0, 1000)
    }

    function test_burstKeepsEveryKey() {
        const field = createTemporaryObject(fieldComponent, testCase)
        for (let index = 0; index < 60; index++)
            field.spawn(String(index))

        compare(field.activeBalloonCount, 60)
        compare(field.lifetimeMs, 2000)
        tryCompare(field, "activeBalloonCount", 0, 2300)
    }
}
