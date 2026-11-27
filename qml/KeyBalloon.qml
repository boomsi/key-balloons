import QtQuick

Item {
    id: balloon
    required property string label
    required property int lifetimeMs
    required property real originX
    required property real originY
    required property real rise
    required property real drift
    required property real tilt
    required property bool dark

    width: caption.implicitWidth + 2
    height: caption.implicitHeight + 2
    x: originX - width / 2
    y: originY - height / 2
    scale: 0.86
    rotation: -tilt * 0.3

    function launch() {
        flight.start()
    }

    Text {
        id: caption
        anchors.centerIn: parent
        text: balloon.label
        textFormat: Text.PlainText
        color: balloon.dark ? "#f2f7ff" : "#1d2c48"
        style: Text.Outline
        styleColor: balloon.dark ? "#172137" : "#eaf4ff"
        font.pixelSize: 22
        font.weight: Font.DemiBold
    }

    ParallelAnimation {
        id: flight

        YAnimator {
            target: balloon
            from: balloon.originY - balloon.height / 2
            to: from - balloon.rise
            duration: balloon.lifetimeMs
            easing.bezierCurve: [0.16, 0.63, 0.49, 0.92, 1.0, 1.0]
            easing.type: Easing.BezierSpline
        }
        XAnimator {
            target: balloon
            from: balloon.originX - balloon.width / 2
            to: from + balloon.drift
            duration: balloon.lifetimeMs
            easing.type: Easing.OutCubic
        }
        RotationAnimator {
            target: balloon
            from: -balloon.tilt * 0.3
            to: balloon.tilt
            duration: balloon.lifetimeMs
            easing.type: Easing.InOutSine
        }
        ScaleAnimator {
            target: balloon
            from: 0.86
            to: 1.0
            duration: Math.min(240, balloon.lifetimeMs)
            easing.type: Easing.OutCubic
        }
        OpacityAnimator {
            target: balloon
            from: 1.0
            to: 0.0
            duration: balloon.lifetimeMs
            easing.type: Easing.InCubic
        }

        onFinished: balloon.destroy()
    }
}
