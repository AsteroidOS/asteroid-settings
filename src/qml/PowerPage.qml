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
    property int depth
    property var pop

    property var pendingAction

    ListModel {
        id: powerModel
        //% "Power Off"
        ListElement { text: qsTrId("id-poweroff-page"); icon: "ios-power-outline"; action: function() { login1DBus.call("PowerOff", [false]) } }
        //% "Reboot"
        ListElement { text: qsTrId("id-reboot-page"); icon: "ios-sync"; action: function() { login1DBus.reboot("") } }
        //% "Bootloader"
        ListElement { text: qsTrId("id-reboot-bootloader-page"); icon: "ios-bootloader-outline"; action: function() { login1DBus.reboot("bootloader") } }
        //% "Timepiece"
        ListElement { text: qsTrId("id-timepiece"); icon: "ios-watch"; available: function() { return coprocessor.hasTimepieceMode }; action: function() { coprocessor.enterTimepieceMode() } }
    }

    ListView {
        id: powerItems
        model: powerModel
        anchors {
            top: parent.top
            topMargin: pageHeader.height
            bottom: parent.bottom
        }
        width: parent.width
        footer: Item { width: parent.width; height: Dims.l(15) }
        delegate: ListItem {
            title: text
            iconName: icon
            visible: !model.available || model.available()
            height: visible ? Dims.h(21) : 0
            HighlightBar {
                onClicked: {
                    pendingAction = action
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
        onTriggered: pendingAction()
    }

    DBusInterface {
        id: login1DBus
        bus: DBus.SystemBus
        service: "org.freedesktop.login1"
        path: "/org/freedesktop/login1"
        iface: "org.freedesktop.login1.Manager"
        function reboot(parameter) {
            call("SetRebootParameter", [parameter])
            call("Reboot", [false])
        }
    }

    PageHeader {
        id: pageHeader
        text: qsTrId("id-power-page")
    }
}
