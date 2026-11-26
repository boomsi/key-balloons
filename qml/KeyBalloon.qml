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

    width: Math.max(40, caption.implicitWidth + 22)
    height: 34
    x: originX - width / 2
    y: originY - height / 2
    scale: 0.86
    rotation: -tilt * 0.3

    function launch() {
        flight.start()
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        border.width: 1
        border.color: balloon.dark ? "#78dfefff" : "#b4ffffff"
        gradient: Gradient {
            GradientStop { position: 0.0; color: balloon.dark ? "#e6576886" : "#f5ffffff" }
            GradientStop { position: 0.53; color: balloon.dark ? "#eb2c3951" : "#eadde8fa" }
            GradientStop { position: 1.0; color: balloon.dark ? "#f01b283d" : "#e2aebfdb" }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: height / 2
        color: "transparent"
        border.width: 1
        border.color: balloon.dark ? "#2322d4ff" : "#31ffffff"
    }

    Text {
        id: caption
        anchors.centerIn: parent
        text: balloon.label
        textFormat: Text.PlainText
        color: balloon.dark ? "#f2f7ff" : "#1d2c48"
        font.pixelSize: 14
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
