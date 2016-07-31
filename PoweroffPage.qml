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

Rectangle {
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#777777" }
            GradientStop { position: 1.0; color: "#2d2d2d" }
        }
    }

    Item {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.horizontalCenter
        width: parent.width*0.3
        height: width
        Icon {
            color: "white"
            name: "power"
            anchors.top: parent.top
            anchors.horizontalCenter: DeviceInfo.hasRoundScreen ? undefined : parent.horizontalCenter
            anchors.left: DeviceInfo.hasRoundScreen ? parent.left : undefined
            anchors.leftMargin: DeviceInfo.hasRoundScreen ? Units.dp(10) : undefined
        }
        Text {
            text: qsTr("Turn off")
            color: "white"
            font.pointSize: 11
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: DeviceInfo.hasRoundScreen ? parent.verticalCenter : undefined
            anchors.bottom: DeviceInfo.hasRoundScreen ? undefined : parent.bottom
            anchors.bottomMargin: Units.dp(5)
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: dsmeDbus.call("req_shutdown", [])
        }
    }

    Item {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.horizontalCenter
        width: parent.width*0.3
        height: width
        Icon {
            color: "white"
            name: "refresh"
            anchors.top: parent.top
            anchors.horizontalCenter: DeviceInfo.hasRoundScreen ? undefined : parent.horizontalCenter
            anchors.left: DeviceInfo.hasRoundScreen ? parent.left : undefined
            anchors.leftMargin: DeviceInfo.hasRoundScreen ? Units.dp(10) : undefined
        }
        Text {
            text: qsTr("Restart")
            color: "white"
            font.pointSize: 11
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: DeviceInfo.hasRoundScreen ? parent.verticalCenter : undefined
            anchors.bottom: DeviceInfo.hasRoundScreen ? undefined : parent.bottom
            anchors.bottomMargin: Units.dp(5)
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: dsmeDbus.call("req_reboot", [])
        }
    }

    DBusInterface {
        id: dsmeDbus
        bus: DBus.SystemBus
        service: "com.nokia.dsme"
        path: "/com/nokia/dsme/request"
        iface: "com.nokia.dsme.request"
    }
}

