/*
 * Copyright (C) 2017 - Florent Revest <revestflo@gmail.com>
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
import QtMultimedia 5.8
import org.asteroid.controls 1.0
import org.asteroid.settings 1.0

Item {
    VolumeControl { id: volumeControl }

    Icon {
        width: Dims.w(25)
        height: width
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Dims.h(15)
        name: "ios-volume-up"
    }

    Label {
        //% "Volume %1%"
        text: qsTrId("id-sound-percentage").arg(volumeControl.volume)
        font.pixelSize: Dims.l(6)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
        anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: Dims.w(2); anchors.rightMargin: Dims.w(2)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Dims.h(10)
    }

    IconButton {
        iconName: "ios-remove-circle-outline"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -Dims.w(15)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Dims.h(10)
        onClicked: {
            var newVal = volumeControl.volume - 10
            if(newVal < 0) newVal = 0
            volumeControl.volume = newVal
        }
    }

    IconButton {
        iconName: "ios-add-circle-outline"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: Dims.w(15)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Dims.h(10)
        onClicked: {
            var newVal = volumeControl.volume + 10
            if(newVal > 100) newVal = 100
            volumeControl.volume = newVal
        }
    }
}

