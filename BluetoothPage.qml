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
import QtQuick.Layouts 1.1

Rectangle {
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#777777" }
            GradientStop { position: 1.0; color: "#2d2d2d" }
        }
    }

    GridLayout {
        columns: 2
        anchors.fill: parent
        anchors.margins: 20
        rowSpacing: 10
        columnSpacing: 10

        Text {
            text: qsTr("Use Bluetooth")
            color: "white"
        }
        Switch {
            id: btSwitch
            anchors.right: parent.right
        }

        Text {
            text: qsTr("Sync notifications")
            color: "white"
        }
        Switch {
            id: notifSwitch
            anchors.right: parent.right
        }

        Text {
            text: qsTr("Sync time")
            color: "white"
        }
        Switch {
            id: timeSwitch
            anchors.right: parent.right
        }
    }
}

