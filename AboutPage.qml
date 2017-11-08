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

import QtQuick 2.9
import org.asteroid.controls 1.0

Item {
    Image {
        fillMode: Image.PreserveAspectFit
        source: "qrc:///asteroidos-logo.svg"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Dims.h(7)
        anchors.top: parent.top
        anchors.bottom: osLabel.top
    }
    Label {
        id: osLabel
        text: "<b>AsteroidOS</b>"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: releaseLabel.top
    }
    Label {
        id: releaseLabel
        text: "Alpha 1.0"
        opacity: 0.8
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Dims.h(7)
    }
}

