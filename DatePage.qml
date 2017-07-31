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
import org.nemomobile.systemsettings 1.0

Item {
    id: root
    property var pop

    DateTimeSettings { id: dtSettings }

    Text {
        id: title
        color: "white"
        text: qsTr("Select a date:")
        height: Dims.h(20)
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    Row {
        id: dateSelector
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        height: Dims.h(60)

        ListView {
            id: dayLV
            height: parent.height
            width: Dims.w(50)
            clip: true
            spacing: Dims.h(2)
            model: 31
            delegate: Item {
                width: dayLV.width
                height: Dims.h(10)
                Text {
                    text: index+1
                    anchors.centerIn: parent
                    color: parent.ListView.isCurrentItem ? "white" : "lightgrey"
                    scale: parent.ListView.isCurrentItem ? 1.5 : 1
                    Behavior on scale { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { } }
                }
            }
            preferredHighlightBegin: height / 2 - Dims.h(5)
            preferredHighlightEnd: height / 2 + Dims.h(5)
            highlightRangeMode: ListView.StrictlyEnforceRange
        }

        Rectangle {
            width: 1
            height: parent.height*0.8
            color: "lightgrey"
            anchors.verticalCenter: parent.verticalCenter
        }

        ListView {
            id: monthLV
            height: parent.height
            width: Dims.w(50)
            clip: true
            spacing: Dims.h(2)
            model: 12
            delegate: Item {
                width: monthLV.width
                height: Dims.h(10)
                Text {
                    text: Qt.locale().monthName(index, Locale.ShortFormat)
                    anchors.centerIn: parent
                    color: parent.ListView.isCurrentItem ? "white" : "lightgrey"
                    scale: parent.ListView.isCurrentItem ? 1.5 : 1
                    Behavior on scale { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { } }
                }
            }
            preferredHighlightBegin: height / 2 - Dims.h(5)
            preferredHighlightEnd: height / 2 + Dims.h(5)
            highlightRangeMode: ListView.StrictlyEnforceRange
        }

        Rectangle {
            width: 1
            height: parent.height*0.8
            color: "lightgrey"
            anchors.verticalCenter: parent.verticalCenter
        }

        ListView {
            id: yearLV
            height: parent.height
            width: Dims.w(50)
            clip: true
            spacing: Dims.h(2)
            model: 100
            delegate: Item {
                width: yearLV.width
                height: Dims.h(10)
                Text {
                    text: index+2000
                    anchors.centerIn: parent
                    color: parent.ListView.isCurrentItem ? "white" : "lightgrey"
                    scale: parent.ListView.isCurrentItem ? 1.5 : 1
                    Behavior on scale { NumberAnimation { duration: 200 } }
                    Behavior on color { ColorAnimation { } }
                }
            }
            preferredHighlightBegin: height / 2 - Dims.h(5)
            preferredHighlightEnd: height / 2 + Dims.h(5)
            highlightRangeMode: ListView.StrictlyEnforceRange
        }
    }

    Component.onCompleted: {
        var d = new Date();
        dayLV.currentIndex = d.getDate()-1;
        monthLV.currentIndex = d.getMonth();
        yearLV.currentIndex = d.getFullYear()-2000;

    }

    IconButton {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Dims.iconButtonMargin

        iconColor: "white"
        pressedIconColor: "lightgrey"
        iconName: "ios-checkmark-circle-outline"

        onClicked: {
            var date = new Date();
            date.setDate(dayLV.currentIndex+1)
            date.setMonth(monthLV.currentIndex)
            date.setFullYear(yearLV.currentIndex+2000)
            dtSettings.setDate(date)

            root.pop();
        }
    }
}

