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

    property int soundMute: 0

    Rectangle {
        id: soundBackground
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Dims.h(13)
        color: "black"
        radius: width/2
        opacity: soundMute > 0 ? 0.2 : 0.4
        width: parent.height*0.25
        height: width

        MouseArea {
            id: muteButton

            anchors.fill: parent
            onClicked: {
                // Is muted?
                if (soundMute > 0) {
                    // Restore pre mute volume value
                    volumeControl.volume = soundMute
                    soundMute = 0
                } else {
                    // Store volume value before muting
                    soundMute = volumeControl.volume
                    volumeControl.volume = "0"
                }
            }

        }
    }

    Icon {
        width: Dims.w(25)
        height: width
        anchors.fill: soundBackground
        anchors.margins: Dims.l(3)
        name: soundMute > 0 ? "ios-sound-indicator-mute" :
                              volumeControl.volume > "70" ? "ios-sound-indicator-high" :
                                                            volumeControl.volume > "30" ? "ios-sound-indicator-mid" :
                                                                                          volumeControl.volume > "0" ? "ios-sound-indicator-low" : "ios-sound-indicator-off"
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

