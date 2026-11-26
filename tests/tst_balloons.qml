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
        verify(field.lifetimeMs <= 3000)
        tryCompare(field, "activeBalloonCount", 0, 3000)
    }
}
