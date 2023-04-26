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
import org.asteroid.settings 1.0
import Nemo.DBus 2.0

Item {

    PageHeader {
        id: title
        text: qsTrId("id-power-page")
    }

    property string powerCommand: "power-off"
    property bool selectedPowerOff: true
    property bool selectedReboot: false

    ListView {
        anchors.fill: parent
        contentHeight: Dims.h(60)
        contentWidth: width

        Column {
            id: settingsColumn
            anchors.fill: parent

            Item { width: parent.width; height:  Dims.h(29) }

            ListItem {
                //% "Power Off"
                title: qsTrId("id-poweroff-page")
                iconName: "ios-power-outline"
                highlight: selectedPowerOff ? 0.2 : 0
                onClicked: {
                    powerCommand = "power-off"
                    if (!selectedPowerOff) {
                        selectedPowerOff = !selectedPowerOff
                        selectedReboot = !selectedReboot
                    }
                }
            }
            ListItem {
                //% "Reboot"
                title: qsTrId("id-reboot-page")
                iconName: "ios-sync"
                highlight: selectedReboot ? 0.2 : 0
                onClicked: {
                    powerCommand = "reboot"
                    if (!selectedReboot) {
                        selectedReboot = !selectedReboot
                        selectedPowerOff = !selectedPowerOff
                    }
                }
            }
        }
    }

    IconButton {
        iconName: "ios-checkmark-circle-outline"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Dims.h(5)
        onClicked: powerCommand === "reboot" ? dsmeDbus.call("req_reboot", []) : dsmeDbus.call("req_shutdown", [])
    }

    DBusInterface {
        id: dsmeDbus
        bus: DBus.SystemBus
        service: "com.nokia.dsme"
        path: "/com/nokia/dsme/request"
        iface: "com.nokia.dsme.request"
    }
}

