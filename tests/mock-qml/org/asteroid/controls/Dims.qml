pragma Singleton
import QtQuick 2.9

QtObject {
    readonly property real iconButtonMargin: 10

    function w(percent) { return percent * 3.2 }
    function h(percent) { return percent * 3.2 }
    function l(percent) { return percent * 3.2 }
}
