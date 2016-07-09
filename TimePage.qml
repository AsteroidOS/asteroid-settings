/*
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
import QtQuick.Layouts 1.1
import org.asteroid.controls 1.0
import org.nemomobile.time 1.0
import org.nemomobile.systemsettings 1.0

Rectangle {
    DateTimeSettings {
        id: dtSettings
    }

    WallClock {
        id: wallClock
    }

    TimePicker {
        id: timePicker
        anchors.fill: parent
        onHoursChanged: {
            if (hours == 24)
                hours = 0
            dtSettings.setTime(timePicker.hours, timePicker.minutes)
        }

        onMinutesChanged: {
            if (minutes == 60)
                minutes = 0
            dtSettings.setTime(timePicker.hours, timePicker.minutes)
        }
    }
    Component.onCompleted: {
        timePicker.hours   = wallClock.time.getHours();
        timePicker.minutes = wallClock.time.getMinutes();
    }
}

