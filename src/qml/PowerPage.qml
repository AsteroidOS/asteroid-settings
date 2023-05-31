/*
 * Copyright (C) 2023 - Timo Könnecke <github.com/eLtMosen>
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

    ListModel {
        id: powerModel
        //% "Power Off"
        ListElement { text: qsTrId("id-poweroff-page"); icon: "ios-power-outline" }
        //% "Reboot"
        ListElement { text: qsTrId("id-reboot-page"); icon: "ios-sync" }
        //% "Bootloader"
        ListElement { text: qsTrId("id-reboot-bootloader-page"); icon: "ios-bootloader-outline" }

    }

    ListView {
        id: powerItems
        model: powerModel
        anchors {
            top: parent.top
            topMargin: parent.height * 0.15
        }
        height: parent.height
        width: parent.width
        delegate: ListItem {
            title: text
            iconName: icon
            highlight: powerItems.currentIndex == index ? 0.2 : 0
            onClicked: powerItems.currentIndex = index
        }
    }

    IconButton {
        iconName: "ios-checkmark-circle-outline"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.05
        onClicked: login1DBus.command(powerItems.currentIndex)
    }

    DBusInterface {
        id: login1DBus
        bus: DBus.SystemBus
        service: "org.freedesktop.login1"
        path: "/org/freedesktop/login1"
        iface: "org.freedesktop.login1.Manager"
        function command(num) {
            switch(num) {
                case 0:
                    call("PowerOff",[false]);
                    break;
                case 1:
                    call("SetRebootParameter", [""])
                    call("Reboot",[false]);
                    break;
                case 2:
                    call("SetRebootParameter", ["bootloader"])
                    call("Reboot",[false]);
                    break;
                default:
                    console.log("Error: bad case ", num, " in login1DBus command");
            }
        }
    }
    PageHeader {
        text: qsTrId("id-power-page")
    }
}
