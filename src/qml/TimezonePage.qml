/*
 * Copyright (C) 2023 - Arseniy Movshev <dodoradio@outlook.com>
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
    property string selectedTz: ""
    property var timezoneList: []
    property int regionLevel: 0
    property string regionPath: ""

    PageHeader {
        id: title
        text: qsTrId("id-timezone-page")
    }

    onTimezoneListChanged: {
        var processedRegionList = [];
        timezoneList.forEach(function(region) {
            //console.log("processing ", region);
            if(region.includes(regionPath)) {
                var tzAsList = region.split("/")
                if (tzAsList.length > (regionLevel + 1)) { //check if this item in the list has children
                    if (processedRegionList.indexOf(tzAsList[regionLevel]) < 0) {
                        processedRegionList.push(tzAsList[regionLevel]);
                        timezoneModel.append({"visualName": tzAsList[regionLevel].replace("_"," ") + " ⋯", "name": tzAsList[regionLevel],"fullPath": region, "bottomLevel": false});
                    }
                } else { //if this item doesn't have children - add it with a full name
                    timezoneModel.append({"visualName": tzAsList[regionLevel].replace("_"," "), "name": tzAsList[regionLevel], "fullPath": region, "bottomLevel": true});
                }
            } else {
                //console.log("skipping ", region, " because it does not contain ", regionPath, " which is the region path");
            }
        });
    }

    ListModel {
        id: timezoneModel
        Component.onCompleted: {
            if (!root.selectedTz) {
                root.selectedTz = timedateDbus.getProperty("Timezone");
            };
            if (root.timezoneList.length < 1) {
                timedateDbus.call("ListTimezones", undefined, function(m) {
                    timezoneModel.clear();
                    root.timezoneList = m;
                });
            };
        }
    }

    Spinner {
        id: timezoneSpinner
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        height: Dims.h(60)
        model: timezoneModel

        delegate: SpinnerDelegate {
            text: visualName
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if(!model.bottomLevel) {
                        layerStack.push(timezoneLayer,{"regionLevel": root.regionLevel + 1, "regionPath": root.regionPath + model.name + "/", "selectedTz": root.selectedTz, "timezoneList": root.timezoneList})
                    }
                }
            }
        }
    }

    IconButton {
        iconName: "ios-checkmark-circle-outline"
        anchors { 
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: Dims.iconButtonMargin
        }

        onClicked: {
            if((root.regionPath + timezoneModel.get(timezoneSpinner.currentIndex).name) == root.selectedTz) {
                app.backToMainMenu();
            } else {
                if(timezoneModel.get(timezoneSpinner.currentIndex).bottomLevel) {
                    var tzname = timezoneModel.get(timezoneSpinner.currentIndex).fullPath;
                    console.log("Attempting to set timezone to ",tzname);
                    timedateDbus.typedCall("SetTimezone", [
                            { "type":"s", "value": tzname },
                            { "type":"b", "value":"0" }
                        ],
                        function(result) { console.log('call completed with:', result) },
                    function(error, message) { console.log('call failed', error, 'message:', message) }
                    );
                    root.selectedTz = timezoneModel.get(timezoneSpinner.currentIndex).fullPath;
                } else {
                    layerStack.push(timezoneLayer,{"regionLevel": root.regionLevel + 1, "regionPath": root.regionPath + timezoneModel.get(timezoneSpinner.currentIndex).name + "/", "selectedTz": root.selectedTz})
                }
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
