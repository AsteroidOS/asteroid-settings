/*
 * CompactListItem — Same as ListItem but with reduced icon-to-text spacing.
 *
 * Icon leftMargin halved: Dims.w(18) → Dims.w(12)
 * Label leftMargin halved: Dims.w(6) → Dims.w(3)
 */

import QtQuick 2.9
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0

Item {
    property alias title: label.text
    property alias iconName: icon.name
    property alias highlight: highlight.forceOn
    property int iconSize: height - Dims.h(6)
    property int labelFontSize: Dims.l(9)
    signal clicked()

    width: parent.width
    height: Dims.h(21)

    HighlightBar {
        id: highlight
        onClicked: parent.clicked()
    }

    Icon {
        id: icon
        width: iconSize
        height: width
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(5)
        }
    }

    Label {
        id: label
        anchors {
            leftMargin: Dims.w(1)
            left: icon.right
            verticalCenter: parent.verticalCenter
        }
        font {
            pixelSize: labelFontSize
            styleName: "SemiCondensed Light"
        }
    }
}
