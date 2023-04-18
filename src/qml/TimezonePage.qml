/*
 * Copyright (C) 2023 - Ed Beroset <beroset@ieee.org>
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
import Nemo.DBus 2.0

Item {
    id: root
    property var pop
    property int currentIndex: -1

    PageHeader {
        id: title
        text: qsTrId("id-timezone-page")
    }

    ListModel {
        id: timezoneModel
        Component.onCompleted: {
            var currentTZ = timedateDbus.getProperty("Timezone");
            timedateDbus.call("ListTimezones", undefined, function(m) {
                timezoneModel.clear();
                var i = 0;
                m.forEach(function(region) {
                    timezoneModel.append({"timezoneName": region});
                    if (region == currentTZ) {
                        currentIndex = i;
                        timezoneList.positionViewAtIndex(i, ListView.SnapPosition)
                    }
                    ++i;
                });
            });
        }
    }

    Spinner {
        id: timezoneList
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        height: Dims.h(60)
        model: timezoneModel

        delegate: SpinnerDelegate { text: timezoneName }
    }

    IconButton {
        iconName: "ios-checkmark-circle-outline"
        anchors { 
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: Dims.iconButtonMargin
        }

        onClicked: {
            if(timezoneList.currentIndex == root.currentIndex) {
                root.pop();
            } else {
                var tzname = timezoneModel.get(timezoneList.currentIndex).timezoneName;
                console.log("Attempting to set timezone to ",tzname);
                timedateDbus.typedCall("SetTimezone", [
                        { "type":"s", "value": tzname },
                        { "type":"b", "value":"0" }
                    ],
                    function(result) { console.log('call completed with:', result) },
                   function(error, message) { console.log('call failed', error, 'message:', message) }
                );
            }
        }
    }

    DBusInterface {
        id: timedateDbus
        bus: DBus.SystemBus
        service: "org.freedesktop.timedate1"
        path: "/org/freedesktop/timedate1"
        iface: "org.freedesktop.timedate1"
    }
}
