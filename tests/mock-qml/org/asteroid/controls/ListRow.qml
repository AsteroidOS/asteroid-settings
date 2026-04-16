import QtQuick 2.9

Item {
    property string text: ""
    property Component actionComponent: null
    property alias actionArea: loader
    property bool highlightBarEnabled: true
    property int actionSlotPadding: 10
    property int rowMargin: 15
    property int iconSize: 20
    property int labelFontSize: 10
    default property alias content: inner.data
    signal clicked()

    Item { id: inner }
    Loader { id: loader; sourceComponent: actionComponent }
}
