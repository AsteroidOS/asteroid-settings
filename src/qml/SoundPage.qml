/*
 * Copyright (C) 2023 - Timo Könnecke <github.com/eLtMosen>
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
import Nemo.Configuration 1.0


Item {
    VolumeControl { id: volumeControl }

    ConfigurationValue {
        id: preMuteLevel

        key: "/desktop/asteroid/pre-mute-level"
    }

    property int soundMute: 0

    Rectangle {
        id: soundBackground
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Dims.h(24)
        color: "black"
        radius: width/2
        opacity: preMuteLevel.value > 0 ? 0.2 : 0.4
        width: Dims.w(27)
        height: width

        MouseArea {
            id: muteButton

            anchors.fill: parent
            onClicked: {
                // Is muted?
                if (preMuteLevel.value > 0) {
                    // Restore pre mute volume value
                    volumeControl.volume = preMuteLevel.value
                    preMuteLevel.value = 0
                } else {
                    // Store volume value before muting
                    preMuteLevel.value = volumeControl.volume
                    volumeControl.volume = "0"
                }
            }

        }
    }

    Icon {
        id: volumeIcon
        width: Dims.w(25)
        height: width
        anchors.fill: soundBackground
        anchors.margins: Dims.l(3)
        name: preMuteLevel.value > 0 ? "ios-sound-indicator-mute" :
                              volumeControl.volume > "70" ? "ios-sound-indicator-high" :
                                                            volumeControl.volume > "30" ? "ios-sound-indicator-mid" :
                                                                                          volumeControl.volume > "0" ? "ios-sound-indicator-low" : "ios-sound-indicator-off"
    }

    Column {
        width: parent.width
        anchors {
            top: volumeIcon.bottom
            topMargin: Dims.h(5)
        }

        Label {
            //% "Volume"
            text: qsTrId("id-sound-percentage")
            width: parent.width
            height: Dims.l(12)
            font.pixelSize: Dims.l(6)
            verticalAlignment: Text.AlignBottom
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        IntSelector {
            width: parent.width
            height: Dims.h(25)
            stepSize: 10
            value: volumeControl.volume
            onValueChanged: {
                volumeControl.volume = value
                // Un-mute if muted
                if (preMuteLevel.value > 0) {
                    // Restore pre mute volume value
                    volumeControl.volume = preMuteLevel.value
                    preMuteLevel.value = 0
                }
            }
        }
    }
}

