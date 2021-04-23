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

import QtQuick 2.9
import org.asteroid.controls 1.0
import Nemo.DBus 2.0

Item {
    id: root
    property var pop

    Label {
        //% "Power off AsteroidOS"
        text: qsTrId("id-poweroff-warn")
        anchors.centerIn: parent
    }

    IconButton {
        iconName: "ios-close-circle-outline"
        edge: undefinedEdge
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -Dims.w(15)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Dims.h(15)
        onClicked: root.pop()
    }

    IconButton {
        iconName: "ios-checkmark-circle-outline"
        edge: undefinedEdge
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: Dims.w(15)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Dims.h(15)
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

