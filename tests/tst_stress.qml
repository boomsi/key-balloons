import QtQuick
import QtQuick.Window
import QtTest
import "../qml" as Ui

TestCase {
    id: testCase
    name: "SustainedAnimation"
    width: 360
    height: 325
    visible: true
    when: windowShown

    property bool measuring: false
    property double lastFrame: 0
    property var pendingSpawns: []
    property var frameIntervals: []
    property var framesAfterSpawn: []

    Ui.BalloonField {
        id: field
        anchors.fill: parent
    }

    Connections {
        target: field.Window.window

        function onFrameSwapped() {
            if (!testCase.measuring)
                return

            const now = Date.now()
            if (testCase.lastFrame > 0)
                testCase.frameIntervals.push(now - testCase.lastFrame)
            for (const spawned of testCase.pendingSpawns)
                testCase.framesAfterSpawn.push(now - spawned)
            testCase.pendingSpawns.length = 0
            testCase.lastFrame = now
        }
    }

    function p95(values) {
        values.sort((left, right) => left - right)
        return values[Math.ceil(values.length * 0.95) - 1]
    }

    function test_sustainedTyping() {
        const start = Date.now()
        let peak = 0
        measuring = true

        for (let index = 0; index < 600; index++) {
            const remaining = start + index * 50 - Date.now()
            if (remaining > 0)
                wait(remaining)

            pendingSpawns.push(Date.now())
            const balloon = field.spawn(String.fromCharCode(65 + index % 26))
            verify(balloon !== null)
            peak = Math.max(peak, field.activeBalloonCount)
        }

        tryCompare(field, "activeBalloonCount", 0, 3200)
        measuring = false
        verify(peak >= 45, "Only " + peak + " balloons were simultaneously active")
        verify(frameIntervals.length > 0, "The test window did not present any frames")
        compare(framesAfterSpawn.length, 600)
        console.info("Key Balloons stress: 600 inputs, peak " + peak
                     + ", frame interval p95 " + p95(frameIntervals) + " ms"
                     + ", spawn-to-next-frame p95 " + p95(framesAfterSpawn) + " ms")
    }
}
