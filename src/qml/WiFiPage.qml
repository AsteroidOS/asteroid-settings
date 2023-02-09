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

    InputPanel {
        id: inputPanel
        z: 99
        visible: active
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: -Dims.h(25)
        height: Dims.h(100)

        width: Dims.w(100)
        externalLanguageSwitchEnabled: false
    }


    ListView {
        model: wifiModel
        visible: wifiStatus.powered
        anchors.fill: parent
        anchors.leftMargin: Dims.l(15)
        anchors.rightMargin: Dims.l(15)
        header: Item {height: Dims.h(15)}
        footer: Item {height: Dims.h(15)}

        delegate: Item {
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

    StatusPage {
        //% "WiFi on"
        property string bluetoothOnStr: qsTrId("id-wifi-on")
        //% "WiFi off"
        property string bluetoothOffStr: qsTrId("id-wifi-off")
        //% "Connected"
        property string connectedStr: qsTrId("id-connected")
        //% "Not connected"
        property string notConnectedStr: qsTrId("id-disconnected")
        text: "<h3>" + (wifiStatus.powered ? bluetoothOnStr : bluetoothOffStr) + "</h3>\n" + (wifiStatus.connected ? connectedStr : notConnectedStr)
        icon: wifiStatus.powered ? "ios-wifi" : "ios-wifi-outline"
        clickable: true
        onClicked: wifiStatus.powered = !wifiStatus.powered
        activeBackground: wifiStatus.powered
    }

    TextField {
        id: titleField
        width: Dims.w(80)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Dims.h(25)
        //% "Title"
        previewText: qsTrId("id-title-field")
        /*onTextChanged: {
            console.log("OH "+text);
        }*/
    }
}

