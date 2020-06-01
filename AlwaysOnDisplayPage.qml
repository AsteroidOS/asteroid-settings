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
import org.nemomobile.systemsettings 1.0

Item {
    DisplaySettings { id: displaySettings }

    StatusPage {
        //% "Always on Display on"
        property string alwaysOnDisplayOnStr: qsTrId("id-always-on-display-on")
        //% "Always on Display off"
        property string alwaysOnDisplayOffStr: qsTrId("id-always-on-display-off")
        text: "<h3>" + (displaySettings.lowPowerModeEnabled ? alwaysOnDisplayOnStr : alwaysOnDisplayOffStr) + "</h3>\n"
        icon: "md-watch"
        clickable: true
        onClicked: displaySettings.lowPowerModeEnabled = !displaySettings.lowPowerModeEnabled
        activeBackground: displaySettings.lowPowerModeEnabled
    }
}

