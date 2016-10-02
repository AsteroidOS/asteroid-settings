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
import org.asteroid.settings 1.0

Rectangle {
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#777777" }
            GradientStop { position: 1.0; color: "#2d2d2d" }
        }
    }

    BluetoothStatus {
        id: bt_status
        onPoweredChanged: console.log("Powered changed")
    }

    Text {
        text: qsTr("Use Bluetooth")
        color: "white"
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.verticalCenter: btSwitch.verticalCenter
        anchors.margins: 20
    }
    Switch {
        id: btSwitch
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        Component.onCompleted: btSwitch.checked = bt_status.powered
        onCheckedChanged: bt_status.powered = btSwitch.checked
    }

    Icon {
        id: connectedIcon
        visible: btSwitch.checked
        color: "white"
        name: bt_status.connected ? "ios-cloud-done" : "ios-cloud"
        size: parent.width*0.3
        anchors.centerIn: parent
    }
    Text {
        visible: btSwitch.checked
        text:  bt_status.connected ? qsTr("Connected") : qsTr("Not connected")
        color: "white"
        font.pointSize: 11
        horizontalAlignment: Text.AlignHCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: connectedIcon.bottom
    }
}

