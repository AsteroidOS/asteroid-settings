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
import QtQuick.Layouts 1.1
import org.nemomobile.dbus 1.0

Rectangle {
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#777777" }
            GradientStop { position: 1.0; color: "#2d2d2d" }
        }
    }

    DBusInterface {
        id: bluez_adapter_dbus

        destination: "org.bluez"
        path: "/org/bluez/hci0"
        iface: "org.bluez.Adapter1"

        busType: DBusInterface.SystemBus
    }

    DBusInterface {
        id: bluez_advertiser_dbus

        destination: "org.bluez"
        path: "/org/bluez/hci0"
        iface: "org.bluez.LEAdvertisingManager1"
        busType: DBusInterface.SystemBus
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
        checked:  bluez_adapter_dbus.getProperty("Powered")
        onCheckedChanged: bluez_adapter_dbus.setProperty("Powered", btSwitch.checked)
    }

    Item {
        visible: btSwitch.checked
        anchors.centerIn: parent
        width: parent.width*0.3
        height: width
        Icon {
            color: "white"
            name: "ios-radio-outline"
            anchors.top: parent.top
            anchors.horizontalCenter:  parent.horizontalCenter
        }
        Text {
            text: qsTr("Advertise")
            color: "white"
            font.pointSize: 11
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Units.dp(5)
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: bluez_advertiser_dbus.call("RegisterAdvertisement", []) // TODO: Doesn't work
        }
    }
}

