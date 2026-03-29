/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
 *               2023 - Arseniy Movshev <dodoradio@outlook.com>
 *               2023 - Ed Beroset <beroset@ieee.org>
 *               2016 - Sylvia van Os <iamsylvie@openmailbox.org>
 *               2015 - Florent Revest <revestflo@gmail.com>
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

    onTimezoneListChanged: {
        // ---- top level: replace dynamic dedup with curated continent allowlist
        if (regionLevel === 0) {
            var allowlist = ["Africa", "America", "Antarctica", "Arctic", "Asia", "Atlantic", "Australia", "Europe", "Indian", "Pacific"]
            var currentRegion = root.selectedTz.split("/")[0]
            var selectIdx = 5 // ---- default to Atlantic as visual center
            for (var a = 0; a < allowlist.length; a++) {
                timezoneModel.append({"visualName": "  " + allowlist[a] + " ›", "name": allowlist[a], "fullPath": "", "bottomLevel": false});
                if (allowlist[a] === currentRegion)
                    selectIdx = a
            }
            // ---- Zulu: flat single-component entry, no city subpage needed
            timezoneModel.append({"visualName": "Zulu", "name": "Zulu", "fullPath": "Zulu", "bottomLevel": true});
            timezoneSpinner.positionViewAtIndex(selectIdx, ListView.SnapPosition);
            return;
        }
        // ---- city level and below: existing dynamic loop unchanged
        var processedRegionList = [];
        var i = 0;
        timezoneList.forEach(function(region) {
            if(region.includes(regionPath)) {
                var tzAsList = region.split("/")
                if (tzAsList.length > (regionLevel + 1)) {
                    if (processedRegionList.indexOf(tzAsList[regionLevel]) < 0) {
                        processedRegionList.push(tzAsList[regionLevel]);
                        timezoneModel.append({"visualName": "  " + tzAsList[regionLevel].replace("_"," ") + " ›", "name": tzAsList[regionLevel],"fullPath": region, "bottomLevel": false});
                        if(selectedTz.includes(root.regionPath + tzAsList[regionLevel])) {
                            timezoneSpinner.positionViewAtIndex(i, ListView.SnapPosition);
                        }
                        i++;
                    }
                } else {
                    timezoneModel.append({"visualName": tzAsList[regionLevel].replace("_"," "), "name": tzAsList[regionLevel], "fullPath": region, "bottomLevel": true});
                    if(selectedTz.includes(root.regionPath + tzAsList[regionLevel])) {
                        timezoneSpinner.positionViewAtIndex(i, ListView.SnapPosition);
                    }
                    i++;
                }
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
                            { "type":"b", "value": false }
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

    PageHeader {
        id: title
        text: qsTrId("id-timezone-page")
    }

    DBusInterface {
        id: timedateDbus
        bus: DBus.SystemBus
        service: "org.freedesktop.timedate1"
        path: "/org/freedesktop/timedate1"
        iface: "org.freedesktop.timedate1"
    }
}
