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

    Text {
        id: title
        color: "white"
        text: qsTr("Bluetooth:")
        height: parent.height*0.2
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    Switch {
        id: btSwitch
        anchors.top: parent.top
        anchors.topMargin: parent.height/4
        anchors.horizontalCenter: parent.horizontalCenter
        Component.onCompleted: btSwitch.checked = btStatus.powered
        onCheckedChanged: btStatus.powered = btSwitch.checked
    }

    Icon {
        id: connectedIcon
        opacity: btSwitch.checked ? 1.0 : 0.0
        color: "white"
        name: btStatus.connected ? "ios-cloud-done" : "ios-cloud"
        size: parent.width*0.3
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height/4
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
    Text {
        opacity: btSwitch.checked ? 1.0 : 0.0
        text:  btStatus.connected ? qsTr("Connected") : qsTr("Not connected")
        color: "white"
        font.pointSize: 11
        horizontalAlignment: Text.AlignHCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: connectedIcon.bottom
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}

