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
import org.asteroid.controls 1.0

Item {
    id: gridItem
    property alias title: label.text
    property alias iconName: icon.name
    signal clicked()

    width: parent.width
    height: Units.dp(25)

    Icon {
        id: icon
        color: "white"
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: Units.dp(20)
    }
    Text {
        id: label
        color: "white"
        font.pointSize: parent.height/4
        horizontalAlignment: Text.AlignHCenter
        anchors.leftMargin: Units.dp(15)
        anchors.left: icon.right
        anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: gridItem.clicked()
    }

    Rectangle {
        anchors.fill: parent
        color: "white"
        opacity: mouseArea.containsPress ? 0.2 : 0
    }
}

