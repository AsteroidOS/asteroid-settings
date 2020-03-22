/*
 * Copyright (C) 2020 - Darrel Griët <idanlcontact@gmail.com>
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
import org.asteroid.settings 1.0

Item {
    TiltToWake { id: tiltToWake }

    StatusPage {
        //% "Tilt-to-wake on"
        property string tiltToWakeOnStr: qsTrId("id-tilt-to-wake-on")
        //% "Tilt-to-wake off"
        property string tiltToWakeOffStr: qsTrId("id-tilt-to-wake-off")
        text: "<h3>" + (tiltToWake.enabled ? tiltToWakeOnStr : tiltToWakeOffStr) + "</h3>\n"
        icon: tiltToWake.enabled ? "ios-tilttowake-outline" : "ios-tilttowake-off-outline"
        clickable: true
        onClicked: tiltToWake.enabled = !tiltToWake.enabled
        activeBackground: tiltToWake.enabled
    }
}

