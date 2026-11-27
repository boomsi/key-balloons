import QtQuick

Item {
    id: box
    required property bool dark
    implicitWidth: 142
    implicitHeight: 30
    readonly property real mouthY: opening.y + opening.height / 2

    function pulse() {
        reflectedLight.opacity = 0.85
        settle.restart()
    }

    Rectangle {
        x: 6
        y: 5
        width: box.width - 12
        height: box.height - 2
        radius: 11
        color: "#30081424"
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        border.width: 1
        border.color: box.dark ? "#9dc2e4ff" : "#e3ffffff"
        gradient: Gradient {
            GradientStop { position: 0.0; color: box.dark ? "#e588a1be" : "#efffffff" }
            GradientStop { position: 0.34; color: box.dark ? "#d05e789d" : "#e3cfdef4" }
            GradientStop { position: 0.66; color: box.dark ? "#e52b3d59" : "#e8b2c7e9" }
            GradientStop { position: 1.0; color: box.dark ? "#e324324b" : "#e6a0b8da" }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 10
        color: "transparent"
        border.width: 1
        border.color: box.dark ? "#4aafc8e9" : "#83ffffff"
    }

    Rectangle {
        id: opening
        x: 16
        y: 5
        width: box.width - 32
        height: 11
        radius: 6
        border.width: 1
        border.color: box.dark ? "#81bbd9f7" : "#d5ffffff"
        gradient: Gradient {
            GradientStop { position: 0.0; color: box.dark ? "#e6111d31" : "#ae4a6388" }
            GradientStop { position: 1.0; color: box.dark ? "#ed344a67" : "#b68dadd2" }
        }
    }

    Rectangle {
        id: reflectedLight
        x: opening.x + 11
        y: opening.y + opening.height - 2
        width: opening.width - 22
        height: 1
        radius: 1
        color: box.dark ? "#a3e1ff" : "#f8feff"
        opacity: 0.25

        NumberAnimation on opacity {
            id: settle
            to: 0.25
            duration: 380
            easing.type: Easing.OutCubic
            running: false
        }
    }

    Rectangle {
        width: 26
        height: 2
        radius: 1
        anchors.horizontalCenter: parent.horizontalCenter
        y: 22
        color: box.dark ? "#839ebcdb" : "#b26180aa"
    }
}
