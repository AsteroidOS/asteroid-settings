/*
 * Copyright (C) 2020 - Darrel Griët <idanlcontact@gmail.com>
 * Copyright (C) 2015 - Florent Revest <revestflo@gmail.com>
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
import QtQuick.Layouts 1.3
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import org.asteroid.settings 1.0
import org.nemomobile.systemsettings 1.0

Item {
    TapToWake { id: tapToWake }
    TiltToWake { id: tiltToWake }
    DisplaySettings { id: displaySettings }

    PageHeader {
        id: title
        text: qsTrId("id-display-page")
    }

    Flickable {
        anchors.fill: parent
        contentHeight: Dims.h(30) + 3*Dims.h(34)
        boundsBehavior: Flickable.DragOverBounds
        flickableDirection: Flickable.VerticalFlick

        GridLayout {
            id: onOffSettings
            columns: 2
            anchors.fill: parent
            anchors.margins: Dims.l(15)

            Item {
                id: brightnessSetting
                height: Dims.h(30)
                Layout.fillWidth: true
                Layout.columnSpan: 2
                Label {
                    //% "Brightness"
                    text: qsTrId("id-brightness")
                    font.pixelSize: Dims.l(6)
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                }

                IconButton {
                    iconName: "ios-remove-circle-outline"
                    edge: undefinedEdge
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: Dims.h(10)
                    onClicked: {
                        var newVal = displaySettings.brightness - 10
                        if(newVal < 0) newVal = 0
                        displaySettings.brightness = newVal
                    }
                }

                Label {
                    text: displaySettings.brightness + "%"
                    font.pixelSize: Dims.l(6)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: Dims.h(10)
                    height: Dims.h(20)
                }

                IconButton {
                    width: Dims.w(20)
                    height: width
                    iconName: "ios-add-circle-outline"
                    edge: undefinedEdge
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: Dims.h(10)
                    onClicked: {
                        var newVal = displaySettings.brightness + 10
                        if(newVal > 100) newVal = 100
                        displaySettings.brightness = newVal
                    }
                }
            }

            Label {
                //% "Always on Display"
                text: qsTrId("id-always-on-display")
                font.pixelSize: Dims.l(6)
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
                Layout.maximumWidth: Dims.w(50)
            }

            Switch {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                width: Dims.l(20)
                checked: displaySettings.lowPowerModeEnabled
                onCheckedChanged: displaySettings.lowPowerModeEnabled = checked
            }

            Label {
                //% "Tilt-to-wake"
                text: qsTrId("id-tilt-to-wake")
                font.pixelSize: Dims.l(6)
                opacity: !tiltToWake.available ? 0.6 : 1.0
                font.strikeout: !tiltToWake.available
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
                Layout.maximumWidth: Dims.w(50)
            }

            Switch {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                width: Dims.l(20)
                enabled: tiltToWake.available
                checked: tiltToWake.enabled
                onCheckedChanged: tiltToWake.enabled = checked
            }

            Label {
                //% "Tap-to-wake"
                text: qsTrId("id-tap-to-wake")
                font.pixelSize: Dims.l(6)
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
                Layout.maximumWidth: Dims.w(50)
            }

            Switch {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                width: Dims.l(20)
                checked: tapToWake.enabled
                onCheckedChanged: tapToWake.enabled = checked
            }
        }
    }
}

