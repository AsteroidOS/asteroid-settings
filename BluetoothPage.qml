/*
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

import QtQuick 2.1
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0

Item {
    BluetoothStatus {
        id: btStatus
        onPoweredChanged: btSwitch.checked = btStatus.powered
    }

    Rectangle {
        id: btBackground
        visible: availableDays(timestampDay0.value*1000) <= 0
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -parent.height*0.13
        color: "black"
        radius: width/2
        opacity: btStatus.powered ? 0.4 : 0.2
        width: parent.height*0.25
        height: width
    }
    Icon {
        visible: availableDays(timestampDay0.value*1000) <= 0
        anchors.fill: btBackground
        color: "white"
        name: btStatus.powered ? "ios-bluetooth-outline" : "ios-bluetooth-off-outline"
    }
    MouseArea {
        anchors.fill: btBackground
        onClicked: btStatus.powered = !btStatus.powered
    }

    Text {
        id: status
        visible: availableDays(timestampDay0.value*1000) <= 0
        text: "<h3>" + (btStatus.powered ? qsTr("Bluetooth on") : qsTr("Bluetooth off")) + "</h3>\n" + (btStatus.connected ? qsTr("Connected") : qsTr("Not Connected"))
        font.pixelSize: parent.height*0.05
        color: "white"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
        anchors.left: parent.left; anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: parent.height*0.15
    }
}

