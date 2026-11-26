import QtQuick

Item {
    id: field
    readonly property int activeBalloonCount: flights.children.length
    property int lifetimeMs: 2800
    property bool dark: true
    property int nextLane: 0
    readonly property var launchOffsets: [0, 26, -26, 35, -35, 13, -13]
    readonly property var driftOffsets: [0, 67, -68, 101, -101, 35, -35]

    function spawn(label: string): KeyBalloon {
        const lane = nextLane
        nextLane = (lane + 1) % launchOffsets.length
        const balloon = balloonComponent.createObject(flights, {
            label: label,
            lifetimeMs: lifetimeMs,
            originX: width / 2 + launchOffsets[lane],
            originY: box.y + box.mouthY,
            rise: box.y * (0.76 + (lane % 3) * 0.06),
            drift: driftOffsets[lane],
            tilt: driftOffsets[lane] / 10,
            dark: dark
        }) as KeyBalloon
        if (!balloon)
            throw new Error("Could not create a key balloon: " + balloonComponent.errorString())
        box.pulse()
        balloon.launch()
        return balloon
    }

    Item {
        id: flights
        anchors.fill: parent
    }

    GlassBox {
        id: box
        width: implicitWidth
        height: implicitHeight
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 9
        anchors.horizontalCenter: parent.horizontalCenter
        dark: field.dark
    }

    Component {
        id: balloonComponent
        KeyBalloon {}
    }
}
