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
import Nemo.Time 1.0
import Nemo.Configuration 1.0
import org.nemomobile.systemsettings 1.0

Item {
    id: root
    property var pop

    DateTimeSettings { id: dtSettings }
    WallClock { id: wallClock}

    ConfigurationValue {
        id: use12H
        key: "/org/asteroidos/settings/use-12h-format"
        defaultValue: false
    }

    PageHeader {
        id: title
        text: qsTrId("id-time-page")
    }

    Row {
        id: timeSelector
        anchors {
            left: parent.left
            leftMargin: DeviceInfo.hasRoundScreen ? Dims.w(5) : 0
            right: parent.right
            rightMargin: DeviceInfo.hasRoundScreen ? Dims.w(5) : 0
            top: title.bottom
        }
        height: Dims.h(60)

        property int spinnerWidth: use12H.value ? width/3 : width/2

        CircularSpinner {
            id: hourLV
            height: parent.height
            width: parent.spinnerWidth
            model: use12H.value ? 12 : 24
            showSeparator: true
            delegate: SpinnerDelegate { text: (index == 0 && use12H.value) ? "12" : ("0" + index).slice(-2) }
        }

        CircularSpinner {
            id: minuteLV
            height: parent.height
            width: parent.spinnerWidth
            model: 60
            showSeparator: use12H.value
        }

        Spinner {
            id: amPmLV
            height: parent.height
            width: parent.spinnerWidth
            model: 2
            delegate: SpinnerDelegate { text: index == 0 ? "AM" : "PM" }
        }
    }

    Component.onCompleted: {
        var hour = wallClock.time.getHours();
        if(use12H.value) {
            amPmLV.positionViewAtIndex(hour / 12, ListView.SnapPosition);
            hour = hour % 12;
        }
        hourLV.currentIndex = hour;
        minuteLV.currentIndex = wallClock.time.getMinutes();
    }

    IconButton {
        iconName: "ios-checkmark-circle-outline"
        anchors { 
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: Dims.iconButtonMargin
        }

        onClicked: {
            var hour = hourLV.currentIndex;
            if(use12H.value)
                hour += amPmLV.currentIndex*12;

            dtSettings.setTime(hour, minuteLV.currentIndex)

            root.pop()
        }
    }
}
