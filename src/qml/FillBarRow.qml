/*
 * Copyright (C) 2024 - AsteroidOS Contributors
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0

/*
 * FillBarRow — A setting row with a vertical fill-bar indicator on the right.
 *
 * For binary values (e.g. ["off","on"]):
 *   off  → bar is fully grey
 *   on   → bar is fully green
 *
 * For multi-level values (e.g. ["off","low","medium","high","workout"]):
 *   off     → 0% filled  (all grey)
 *   low     → 25% filled (green from bottom)
 *   medium  → 50% filled
 *   high    → 75% filled
 *   workout → 100% filled (all green)
 *
 * Clicking the row cycles to the next value.
 */
ListRow {
    id: root

    property var valueArray: []
    property string currentValue: ""

    signal valueChanged(string value)

    // Shrink the action slot so the bar is compact and doesn't overflow
    iconSize: Dims.l(10)
    actionSlotPadding: Dims.l(1)

    onClicked: {
        if (valueArray.length === 0) return
        var idx = valueArray.indexOf(currentValue)
        var nextIdx = (idx + 1) % valueArray.length
        valueChanged(valueArray[nextIdx])
    }

    // Use a zero-delay timer to install the binding after the Loader is definitely ready.
    // Connections.onStatusChanged can miss the Ready transition on Qt 5.12 when the
    // actionComponent is synchronous inline.
    Timer {
        id: bindingInstaller
        interval: 0; repeat: false
        onTriggered: {
            if (actionArea.status === Loader.Ready && actionArea.item) {
                actionArea.item.fillRatio = Qt.binding(function() {
                    if (root.valueArray.length <= 1) return 0
                    var idx = root.valueArray.indexOf(root.currentValue)
                    if (idx <= 0) return 0
                    return idx / (root.valueArray.length - 1)
                })
            }
        }
    }
    Component.onCompleted: bindingInstaller.start()

    actionComponent: Item {
        property real fillRatio: 0

        Item {
            id: barContainer
            anchors.centerIn: parent
            width: Math.max(Dims.w(1), 3)
            height: parent.height * 0.85

            Rectangle {
                id: trackBg
                anchors.fill: parent
                radius: parent.width / 4
                color: fillRatio > 0 ? "#CCCCCC" : "#888888"

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }

            Rectangle {
                id: fillRect
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.height * fillRatio
                radius: parent.width / 4
                color: "#4CAF50"

                Behavior on height {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }
}
