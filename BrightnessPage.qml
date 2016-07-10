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
import org.nemomobile.systemsettings 1.0

Rectangle {
    Text {
        text: "Brightness: " + displaySettings.brightness + "%"
        anchors.left: brightnessSlider.left
        anchors.bottom: brightnessSlider.top

    }
    Slider {
        id: brightnessSlider
        anchors.centerIn: parent
        width: parent.width*0.9
        value: displaySettings.brightness
        onValueChanged: displaySettings.brightness = brightnessSlider.value
    }
    DisplaySettings {
        id: displaySettings
    }
}

