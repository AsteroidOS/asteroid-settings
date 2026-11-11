/*
 * Copyright (C) 2026 - Darrel Griët <dgriet@gmail.com>
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

import QtQuick
import org.asteroid.controls
import org.asteroid.settings

Item {
    property int depth
    property var pop

    Component.onCompleted: coprocessor.moveHands(0, 0)
    Component.onDestruction: coprocessor.resumeWatchMode()

    component HandRow: Item {
        property int hand
        property alias text: label.text

        width: parent.width
        height: Dims.h(18)

        IconButton {
            id: counterClockwise
            anchors { left: parent.left; leftMargin: Dims.w(12); verticalCenter: parent.verticalCenter }
            width: Dims.w(18)
            height: width
            iconName: "ios-arrow-back"
            onClicked: coprocessor.calibrateHand(hand, Coprocessor.CounterClockwise, 1)
        }

        Label {
            id: label
            anchors.centerIn: parent
            font.pixelSize: Dims.l(7)
        }

        IconButton {
            anchors { right: parent.right; rightMargin: Dims.w(12); verticalCenter: parent.verticalCenter }
            width: counterClockwise.width
            height: width
            iconName: "ios-arrow-forward"
            onClicked: coprocessor.calibrateHand(hand, Coprocessor.Clockwise, 1)
        }
    }

    HandRow {
        anchors { bottom: parent.verticalCenter; bottomMargin: Dims.h(7) }
        hand: Coprocessor.MinuteHand
        //% "Minute hand"
        text: qsTrId("id-hands-calibration-minute")
    }

    HandRow {
        anchors { top: parent.verticalCenter; topMargin: Dims.h(7) }
        hand: Coprocessor.HourHand
        //% "Hour hand"
        text: qsTrId("id-hands-calibration-hour")
    }

    Label {
        anchors { top: parent.verticalCenter; topMargin: Dims.h(27); horizontalCenter: parent.horizontalCenter }
        width: Dims.w(60)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        font.pixelSize: Dims.l(5)
        opacity: 0.8
        //% "Point both hands at 12"
        text: qsTrId("id-hands-calibration-hint")
    }

    PageHeader {
        id: title
        //% "Calibrate hands"
        text: qsTrId("id-hands-calibration-page")
    }
}
