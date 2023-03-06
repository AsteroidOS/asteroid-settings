/*
 * Copyright (C) 2021 - Darrel Griët <idanlcontact@gmail.com>
 * Copyright (C) 2016 - Sylvia van Os <iamsylvie@openmailbox.org>
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
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import Connman 0.2
import QtQuick.VirtualKeyboard 2.4

Item {
    TechnologyModel {
        id: wifiModel
        name: "wifi"
        onCountChanged: {
            console.log("COUNT CHANGE " + count)
        }
        onScanRequestFinished: {
            console.log("SCAN FINISH")
        }
    }

    NetworkTechnology {
        id: wifiStatus
        path: "/net/connman/technology/wifi"
        onPoweredChanged: {
            console.log("POWER CHANGE ") + powered
            if (powered)
                wifiModel.requestScan()
        }
    }

    ListView {
        id: wifiList
        model: wifiModel
        anchors.fill: parent
        anchors.leftMargin: Dims.l(15)
        anchors.rightMargin: Dims.l(15)

        header: Item { //this is just an asteroid statuspage, modified to collapse when wifi is toggled.
            height: wifiStatus.powered ? Dims.h(60) : wifiList.height
            Behavior on height { NumberAnimation { duration: 100 } }

            width: Dims.w(100)
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
                id: statusBackground
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -parent.height*0.13
                color: "black"
                radius: width/2
                opacity: wifiStatus.powered ? 0.4 : 0.2
                width: parent.width*0.25
                height: width
            }
            Icon {
                id: statusIcon
                anchors.fill: statusBackground
                anchors.margins: parent.width*0.03
                name: wifiStatus.powered ? "ios-wifi" : "ios-wifi-outline"
            }
            MouseArea {
                id: statusMA
                enabled: true
                anchors.fill: statusBackground
                onClicked: wifiStatus.powered = !wifiStatus.powered
            }

            Label {
                id: statusLabel
                //% "WiFi on"
                property string wifiOnStr: qsTrId("id-wifi-on")
                //% "WiFi off"
                property string wifiOffStr: qsTrId("id-wifi-off")
                //% "Connected"
                property string connectedStr: qsTrId("id-connected")
                //% "Not connected"
                property string notConnectedStr: qsTrId("id-disconnected")
                text: "<h3>" + (wifiStatus.powered ? wifiOnStr : wifiOffStr) + "</h3>\n" + (wifiStatus.connected ? connectedStr : notConnectedStr)
                font.pixelSize: parent.width*0.05
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
                anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: parent.width*0.04; anchors.rightMargin: anchors.leftMargin
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: parent.width*0.15
            }
        }
        footer: Item {height: wifiStatus.powered ? Dims.h(15) : 0}

        delegate: Item {
            visible: wifiStatus.powered
            property var wifiName: modelData.name
            width: parent.width
            height: Dims.h(16)
            Label {
                id: btName
                text: wifiName
            }
            Label {
                anchors.top: btName.bottom
                opacity: 0.8
                font.pixelSize: Dims.l(5)
                font.weight: Font.Thin
                text: {
                    if (modelData.connected) {
                        "Connected"
                    } else {
                        "Not set up"
                    }
                }
            }
        }
    }
}

