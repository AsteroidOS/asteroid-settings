/*
 * Copyright (C) 2021 Darrel Griët <idanlcontact@gmail.com>
 *               2015 Florent Revest <revestflo@gmail.com>
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
import Qt.labs.folderlistmodel 2.1
import Nemo.Time 1.0
import Nemo.Configuration 1.0
import org.asteroid.controls 1.0
import QtQml.Models 2.15

Item {
    property alias displayAmbient: compositor.displayAmbient
    property bool fakePressed:     false
    property bool toTopAllowed:    false
    property bool toBottomAllowed: false
    property bool toLeftAllowed:   false
    property bool toRightAllowed:  false
    property bool forbidTop:       false
    property bool forbidBottom:    false
    property bool forbidLeft:      false
    property bool forbidRight:     false
    property var launcherCenterColor: alb.centerColor("")
    property var launcherOuterColor: alb.outerColor("")

    ConfigurationValue {
        id: appLauncherSource
        key: "/desktop/asteroid/applauncher"
        defaultValue: "file:///usr/share/asteroid-launcher/applauncher/000-default-horizontal.qml"
    }

    GridView {
        id: grid
        cellWidth: Dims.w(50)
        cellHeight: Dims.h(40)
        anchors.fill: parent

        model: FolderListModel {
            id: folderModel
            folder: "file:///usr/share/asteroid-launcher/applauncher"
            nameFilters: ["*.qml"]
            onCountChanged: {
                var i = 0
                while (i < folderModel.count){
                    var fileName = folderModel.get(i, "fileName")
                    if(appLauncherSource.value == folderModel.folder + "/" + fileName)
                        grid.positionViewAtIndex(i, GridView.Center)

                    i = i+1
                }
            }
        }


        Item {
            id: burnInProtectionManager
            property int leftOffset
            property int rightOffset
            property int topOffset
            property int bottomOffset
            property int widthOffset
            property int heightOffset
        }

        QtObject {
            id: alb
            function outerColor(path) {
                return "#000000";
            }
            function centerColor(path) {
                return "#888888";
            }
        }

        ListModel {
            id: launcherModel
            Component.onCompleted: {
                append({object: {title: "Agenda", iconId: "ios-calendar-outline"}});
                append({object: {title: "Alarm Clock", iconId: "ios-alarm-outline"}});
                append({object: {title: "Calculator", iconId: "ios-calculator-outline"}});
                append({object: {title: "Compass", iconId: "ios-compass-outline"}});
                append({object: {title: "Flashlight", iconId: "ios-bulb-outline"}});
                append({object: {title: "Heart Rate Monitor", iconId: "ios-pulse-outline"}});
                append({object: {title: "Music", iconId: "ios-musical-notes-outline"}});
                append({object: {title: "Settings", iconId: "ios-settings-outline"}});
                append({object: {title: "Stopwatch", iconId: "ios-stopwatch-outline"}});
                append({object: {title: "Timer", iconId: "ios-timer-outline"}});
                append({object: {title: "Weather", iconId: "ios-cloudy-outline"}});
            }
        }

        QtObject {
            id: compositor
            property bool displayAmbient: false
        }

        QtObject {
            id: rightIndicator
            function animate() {}
        }
        QtObject {
            id: leftIndicator
            function animate() {}
        }
        QtObject {
            id: topIndicator
            function animate() {}
        }
        QtObject {
            id: bottomIndicator
            function animate() {}
        }

        WallClock {
            id: wallClock
            enabled: true
            updateFrequency: WallClock.Minute
        }

        QtObject {
            id: localeManager
            property string changesObserver: ""
        }

        delegate: Component {
            id: fileDelegate
            Item {
                width: grid.cellWidth
                height: grid.cellHeight
                Loader {
                    id: preview
                    anchors.centerIn: parent
                    width: Math.min(grid.cellWidth, grid.cellHeight)
                    height: Math.min(grid.cellWidth, grid.cellHeight)
                    source: folderModel.folder + "/" + fileName
                    asynchronous: true
                }

                Timer {
                    interval: 5000
                    triggeredOnStart: true
                    running: preview.status == Loader.Ready && (appLauncherSource.value == folderModel.folder + "/" + fileName)
                    repeat: true
                    onTriggered: {
                        if (preview.item.currentIndex == 0) {
                            preview.item.currentIndex = preview.item.count - 1;
                        } else {
                            preview.item.currentIndex = 0
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: appLauncherSource.value = folderModel.folder + "/" + fileName
                }

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: 0.4
                    visible: appLauncherSource.value == folderModel.folder + "/" + fileName
                }
                Icon {
                    name: "ios-checkmark-circle"
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    height: width
                    width: parent.width*0.3
                    visible: appLauncherSource.value == folderModel.folder + "/" + fileName
                }
            }
        }
    }
}
