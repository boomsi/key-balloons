import QtQuick

Item {
    id: box
    required property bool dark
    implicitWidth: 142
    implicitHeight: 30
    readonly property real mouthY: opening.y + opening.height / 2
    readonly property color accent: dark ? "#bce4d9" : "#2b655a"

    function pulse() {
        reflectedLight.opacity = 0.9
        reflectionFade.restart()
    }

    function mousePulse(event: string) {
        switch (event) {
        case "mouse.left": leftHighlight.flash(); break
        case "mouse.right": rightHighlight.flash(); break
        case "mouse.wheel": wheelHighlight.flash(); break
        }
    }

    function accentAt(alpha: real): color {
        return Qt.rgba(accent.r, accent.g, accent.b, alpha)
    }

    component LightStrip: Rectangle {
        id: strip
        required property real intensity
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: box.accentAt(0) }
            GradientStop { position: 0.25; color: box.accentAt(strip.intensity * 0.55) }
            GradientStop { position: 0.5; color: box.accentAt(strip.intensity) }
            GradientStop { position: 0.75; color: box.accentAt(strip.intensity * 0.55) }
            GradientStop { position: 1.0; color: box.accentAt(0) }
        }
    }

    component MouseHighlight: Item {
        id: highlight
        y: box.height - 13
        height: 8
        opacity: 0

        function flash() {
            flashAnimation.restart()
        }

        LightStrip {
            anchors.centerIn: parent
            width: parent.width
            height: 7
            intensity: 0.17
        }

        LightStrip {
            anchors.centerIn: parent
            width: parent.width * 0.86
            height: 3
            intensity: 0.34
        }

        LightStrip {
            anchors.centerIn: parent
            width: parent.width * 0.76
            height: 1.25
            intensity: 1
        }

        SequentialAnimation {
            id: flashAnimation
            NumberAnimation {
                target: highlight
                property: "opacity"
                to: 0.92
                duration: 38
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: highlight
                property: "opacity"
                to: 0
                duration: 310
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        x: 3
        y: 6
        width: box.width - 6
        height: box.height - 3
        radius: 11
        color: "#1d050809"
    }

    Rectangle {
        x: 7
        y: 8
        width: box.width - 14
        height: box.height - 6
        radius: 9
        color: "#22020608"
    }

    Rectangle {
        anchors.fill: parent
        radius: 11
        gradient: Gradient {
            GradientStop { position: 0.0; color: box.dark ? "#c4838a89" : "#ecfafaf6" }
            GradientStop { position: 0.36; color: box.dark ? "#e63c4142" : "#edc8cac4" }
            GradientStop { position: 1.0; color: box.dark ? "#ed0b0e10" : "#dd777d79" }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 10
            gradient: Gradient {
                GradientStop { position: 0.0; color: box.dark ? "#ee3b4042" : "#f4edeeea" }
                GradientStop { position: 0.45; color: box.dark ? "#f0292d2f" : "#f1d0d4d0" }
                GradientStop { position: 1.0; color: box.dark ? "#f01a1e20" : "#f0b9bfba" }
            }
        }
    }

    Rectangle {
        id: opening
        x: 10
        y: 6
        width: box.width - 20
        height: 9
        radius: height / 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: box.dark ? "#d3090c0e" : "#ab6d7876" }
            GradientStop { position: 1.0; color: box.dark ? "#b25a6463" : "#edfafcf8" }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: box.dark ? "#f00c0f11" : "#db87948f" }
                GradientStop { position: 1.0; color: box.dark ? "#eb1d2425" : "#d2b3c4bd" }
            }
        }

        LightStrip {
            id: reflectedLight
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - 2
            width: parent.width - 12
            height: 1
            opacity: 0.16
            intensity: 0.82

            NumberAnimation on opacity {
                id: reflectionFade
                to: 0.16
                duration: 340
                easing.type: Easing.OutCubic
                running: false
            }
        }
    }

    LightStrip {
        anchors.horizontalCenter: parent.horizontalCenter
        y: box.height - 9.5
        width: box.width - 24
        height: 1
        intensity: 0.07
    }

    MouseHighlight {
        id: leftHighlight
        objectName: "leftMouseHighlight"
        x: 12
        width: box.width / 2 - 22
    }

    MouseHighlight {
        id: rightHighlight
        objectName: "rightMouseHighlight"
        anchors.right: parent.right
        anchors.rightMargin: 12
        width: leftHighlight.width
    }

    MouseHighlight {
        id: wheelHighlight
        objectName: "wheelMouseHighlight"
        anchors.horizontalCenter: parent.horizontalCenter
        width: 20
    }
}
