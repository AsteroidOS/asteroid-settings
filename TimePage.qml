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
import org.nemomobile.time 1.0
import org.nemomobile.systemsettings 1.0

Item {
    id: root
    property var pop

    DateTimeSettings { id: dtSettings }
    WallClock { id: wallClock}

    Text {
        id: title
        text: qsTr("Select a time:")
        color: "white"
        height: parent.height*0.2
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    Row {
        id: timeSelector
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        height: parent.height*0.6

        ListView {
            id: hourLV
            height: parent.height
            width: parent.width/2-1
            clip: true
            spacing: 15
            model: 24
            delegate: Item {
                width: hourLV.width
                height: 30
                Text {
                    text: index
                    anchors.centerIn: parent
                    color: parent.ListView.isCurrentItem ? "white" : "lightgrey"
                    scale: parent.ListView.isCurrentItem ? 1.5 : 1
                    Behavior on scale { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { } }
                }
            }
            preferredHighlightBegin: height / 2 - 15
            preferredHighlightEnd: height / 2 + 15
            highlightRangeMode: ListView.StrictlyEnforceRange
        }

        Rectangle {
            width: 1
            height: parent.height*0.8
            color: "lightgrey"
            anchors.verticalCenter: parent.verticalCenter
        }

        ListView {
            id: minuteLV
            height: parent.height
            width: parent.width/2-1
            clip: true
            spacing: 15
            model: 60
            delegate: Item {
                width: minuteLV.width
                height: 30
                Text {
                    text: index
                    anchors.centerIn: parent
                    color: parent.ListView.isCurrentItem ? "white" : "lightgrey"
                    scale: parent.ListView.isCurrentItem ? 1.5 : 1
                    Behavior on scale { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { } }
                }
            }
            preferredHighlightBegin: height / 2 - 15
            preferredHighlightEnd: height / 2 + 15
            highlightRangeMode: ListView.StrictlyEnforceRange
        }
    }

    Component.onCompleted: {
        hourLV.currentIndex = wallClock.time.getHours();
        minuteLV.currentIndex = wallClock.time.getMinutes();
    }

    IconButton {
        height: parent.height*0.2
        width: height
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        iconColor: "white"
        pressedIconColor: "lightgrey"
        iconName: "ios-checkmark-circle-outline"

        onClicked: {
            dtSettings.setTime(hourLV.currentIndex, minuteLV.currentIndex)

            root.pop()
        }
    }
}
