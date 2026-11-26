import QtQuick
import QtQuick.Window

Window {
    id: overlay
    width: 360
    height: 325
    color: "transparent"
    title: qsTr("Key Balloons")
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
           | Qt.WindowTransparentForInput | Qt.WindowDoesNotAcceptFocus

    function showKey(label: string) {
        field.spawn(label)
    }

    BalloonField {
        id: field
        anchors.fill: parent
    }
}
