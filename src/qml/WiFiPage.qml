/*
 * Copyright (C) 2023 - Arseniy Movshev <dodoradio@outlook.com>
 *               2017-2022 - Chupligin Sergey <neochapay@gmail.com>
 *               2021 - Darrel Griët <idanlcontact@gmail.com>
 *               2016 - Sylvia van Os <iamsylvie@openmailbox.org>
 *               2015 - Florent Revest <revestflo@gmail.com>
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

/* A large proportion of this code has been referenced from Nemomobile-UX Glacier-Settings, published at https://github.com/nemomobile-ux/glacier-settings/blob/master/src/plugins/wifi/WifiSettings.qml
 */

import QtQuick 2.9
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import Connman 0.2
import QtQuick.VirtualKeyboard 2.4

Item {
    id: root
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
        width: parent.width*0.7
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.height
        header: Item {
            //this is literally a statuspage
            width: root.width
            height: wifiStatus.powered ? width*0.6 : root.height
            Behavior on height { NumberAnimation { duration: 100 } }
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
                id: statusIconBackground
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -parent.width*0.13
                color: "black"
                radius: width/2
                opacity: wifiStatus.powered ? 0.4 : 0.2
                width: parent.width*0.25
                height: width
                Icon {
                    id: statusIcon
                    anchors.fill: statusIconBackground
                    anchors.margins: parent.width*0.12
                    name: wifiStatus.powered ? "ios-wifi" : "ios-wifi-outline"
                }
                MouseArea {
                    id: statusMA
                    enabled: true
                    anchors.fill: parent
                    onClicked: wifiStatus.powered = !wifiStatus.powered
                }
            }


            Label {
                id: statusLabel
                font.pixelSize: parent.width*0.07
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
                anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: parent.width*0.04; anchors.rightMargin: anchors.leftMargin
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: parent.width*0.15
                text: "<h3>" + (wifiStatus.powered ? qsTrId("id-wifi-on"): qsTrId("id-wifi-off")) + "</h3>\n" + (wifiStatus.connected ? qsTrId("id-wifi-connected") : qsTrId("id-wifi-disconnected"))
            }
        }

        footer: Item {height: wifiStatus.powered ? root.height*0.15 : 0; width: parent.width}

        delegate: MouseArea {
            property var wifiName: modelData.name
            visible: wifiStatus.powered
            width: wifiList.width
            height: wifiStatus.powered ? width*0.23 : 0
            Marquee {
                id: wifiNameLabel
                text: wifiName
                height: parent.height*0.6
                width: parent.width
            }
            Label {
                anchors.top: wifiNameLabel.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: 0.8
                font.pixelSize: parent.width*0.07
                font.weight: Font.Thin
                text: {
                    if (modelData.connected) {
                        qsTrId("id-wifi-connected")
                    } else if (modelData.favorite){
                        qsTrId("id-wifi-saved")
                    } else {
                        qsTrId("id-wifi-notsetup")
                    }
                }
            }
            onClicked: {
                if (modelData.favorite && !modelData.connected) {
                    modelData.requestConnect()
                } else {
                    layerStack.push(connectionDialog, {modelData: modelData})
                }
            }
            onPressAndHold: layerStack.push(connectionDialog, {modelData: modelData})
        }
    }

    Component {
        id: connectionDialog
        WiFiConnectionDialog {}
    }
}

