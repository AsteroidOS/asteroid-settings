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

import QtQuick 2.1
import org.asteroid.controls 1.0
import org.nemomobile.systemsettings 1.0

Item {
    Icon {
        width: parent.height*0.25
        height: width
        size: width
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -parent.height*0.15
        color: "white"
        name: "ios-sunny-outline"
    }

    Text {
        text: qsTr("Brightness %1%").arg(displaySettings.brightness)
        font.pixelSize: parent.height*0.06
        color: "white"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
        anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: width*0.02; anchors.rightMargin: width*0.02
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: parent.height*0.1
    }

    IconButton {
        width: parent.height*0.2
        height: width
        iconSize: width
        iconColor: "white"
        pressedIconColor: "lightgrey"
        iconName: "ios-remove-circle-outline"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -parent.width*0.15
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height*0.1
        onClicked: {
            var newVal = displaySettings.brightness - 10
            if(newVal < 0) newVal = 0
            displaySettings.brightness = newVal
        }
    }

    IconButton {
        width: parent.height*0.2
        height: width
        iconSize: width
        iconColor: "white"
        pressedIconColor: "lightgrey"
        iconName: "ios-add-circle-outline"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: parent.width*0.15
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height*0.1
        onClicked: {
            var newVal = displaySettings.brightness + 10
            if(newVal > 100) newVal = 100
            displaySettings.brightness = newVal
        }
    }

    DisplaySettings {
        id: displaySettings
    }
}

