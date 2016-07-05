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

Item {
    id: gridItem
    property alias title: label.text
    property alias iconName: icon.name
    signal clicked()

    Layout.fillWidth: true
    Layout.fillHeight: true

    Icon {
        id: icon
        color: "black"
        anchors.top: parent.top
        anchors.horizontalCenter: DeviceInfo.hasRoundScreen ? undefined : parent.horizontalCenter
        anchors.left: DeviceInfo.hasRoundScreen ? parent.left : undefined
        anchors.leftMargin: DeviceInfo.hasRoundScreen ? Units.dp(10) : undefined
    }
    Text {
        id: label
        color: "black"
        font.pointSize: 11
        horizontalAlignment: Text.AlignHCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: DeviceInfo.hasRoundScreen ? parent.verticalCenter : undefined
        anchors.bottom: DeviceInfo.hasRoundScreen ? undefined : parent.bottom
        anchors.bottomMargin: Units.dp(5)
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: gridItem.clicked()
    }
}

