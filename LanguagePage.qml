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
import org.nemomobile.systemsettings 1.0

Item {
    id: root
    property var pop

    LanguageModel { id: langSettings }

    Text {
        id: title
        text: qsTr("Select a language:")
        color: "white"
        height: parent.height*0.2
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    Row {
        id: langSelector
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        height: parent.height*0.6

        ListView {
            id: langLV
            height: parent.height
            width: parent.width
            clip: true
            spacing: 15
            model: langSettings
            delegate: Item {
                width: langLV.width
                height: 30
                Text {
                    text: langSettings.languageName(index)
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
        langLV.currentIndex = langSettings.currentIndex;
    }

    IconButton {
        height: parent.height*0.2
        width: height
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        iconColor: "white"
        iconName: "ios-checkmark-circle-outline"

        onClicked: {
            rebootMessage.opacity = 1.0
            delayTimer.start();
        }
    }

    Rectangle {
        id: rebootMessage
        anchors.fill: parent
        color: "black"
        opacity: 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Text {
            anchors.centerIn: parent
            text: qsTr("Rebooting...")
            font.pixelSize: parent.height*0.12
            color: "white"
        }
    }
    Timer {
        id: delayTimer
        interval: 2000
        repeat: false
        onTriggered: langSettings.setSystemLocale(langSettings.locale(langLV.currentIndex), LanguageModel.UpdateAndReboot)
    }
}
