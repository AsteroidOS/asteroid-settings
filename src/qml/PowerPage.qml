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

    ListModel {
        id: powerModel
        //% "Power Off"
        ListElement { text: qsTrId("id-poweroff-page"); icon: "ios-power-outline"; command: "req_shutdown" }
        //% "Reboot"
        ListElement { text: qsTrId("id-reboot-page"); icon: "ios-sync"; command: "req_reboot" }
    }

    ListView {
        id: powerItems
        anchors.fill: parent
        interactive: false
        model: powerModel
        delegate: ListItem {
            title: text
            iconName: icon
            highlight: powerItems.currentIndex == index ? 0.2 : 0
            onClicked: powerItems.currentIndex = index
        }

        preferredHighlightBegin: height / 2 - Dims.h(21)
        preferredHighlightEnd: height / 2 + Dims.h(21)
        highlightRangeMode: ListView.StrictlyEnforceRange
    }

    IconButton {
        iconName: "ios-checkmark-circle-outline"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Dims.h(5)
        onClicked: dsmeDbus.call(powerModel.get(powerItems.currentIndex).command, [])
    }

    DBusInterface {
        id: dsmeDbus
        bus: DBus.SystemBus
        service: "com.nokia.dsme"
        path: "/com/nokia/dsme/request"
        iface: "com.nokia.dsme.request"
    }
}

