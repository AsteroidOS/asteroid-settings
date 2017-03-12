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
import org.nemomobile.dbus 2.0

Item {
    id: root
    property var pop

    Text {
        text: qsTr("Power off AsteroidOS")
        font.pixelSize: parent.height*0.07
        anchors.centerIn: parent
        color: "white"
    }

    IconButton {
        width: parent.height*0.2
        height: width
        iconColor: "white"
        pressedIconColor: "lightgrey"
        iconName: "ios-close-circle-outline"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -parent.width*0.15
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height*0.15
        onClicked: root.pop()
    }

    IconButton {
        width: parent.height*0.2
        height: width
        iconColor: "white"
        pressedIconColor: "lightgrey"
        iconName: "ios-checkmark-circle-outline"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: parent.width*0.15
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height*0.15
        onClicked: dsmeDbus.call("req_shutdown", [])
    }

    DBusInterface {
        id: dsmeDbus
        bus: DBus.SystemBus
        service: "com.nokia.dsme"
        path: "/com/nokia/dsme/request"
        iface: "com.nokia.dsme.request"
    }
}

