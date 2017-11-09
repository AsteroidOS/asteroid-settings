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
import org.asteroid.utils 1.0

Item {
    BluetoothStatus { id: btStatus }

    StatusPage {
        text: "<h3>" + (btStatus.powered ? qsTr("Bluetooth on") : qsTr("Bluetooth off")) + "</h3>\n" + (btStatus.connected ? qsTr("Connected") : qsTr("Not Connected"))
        icon: btStatus.powered ? "ios-bluetooth-outline" : "ios-bluetooth-off-outline"
        clickable: true
        onClicked: btStatus.powered = !btStatus.powered
    }
}

