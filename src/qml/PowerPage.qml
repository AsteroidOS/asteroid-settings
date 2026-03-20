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

import QtQuick
import org.asteroid.controls
import Nemo.DBus

Item {

    property int pendingIndex: -1

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
            topMargin: pageHeader.height
        }
        height: parent.height
        width: parent.width
        delegate: ListItem {
            title: text
            iconName: icon
            HighlightBar {
                onClicked: {
                    pendingIndex = index
                    remorse.action = text
                    remorse.start()
                }
            }
        }
    }

    RemorseTimer {
        id: remorse
        duration: 3000
        //% "Tap to cancel"
        cancelText: qsTrId("id-tap-to-cancel")
        onTriggered: login1DBus.command(pendingIndex)
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
        id: pageHeader
        text: qsTrId("id-power-page")
    }
}
