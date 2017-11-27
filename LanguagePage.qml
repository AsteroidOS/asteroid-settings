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

    LanguageModel { id: langSettings }

    PageHeader {
        id: title
        text: qsTrId("id-language-page")
    }

    Spinner {
        id: langLV
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        height: Dims.h(60)
        model: langSettings

        delegate: SpinnerDelegate { text: langSettings.languageName(index) }
    }

    Component.onCompleted: langLV.currentIndex = langSettings.currentIndex;

    IconButton {
        iconName: "ios-checkmark-circle-outline"

        onClicked: {
            if(langLV.currentIndex == langSettings.currentIndex) {
                root.pop();
                return;
            }
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

        Label {
            anchors.centerIn: parent
            //% "Rebooting..."
            text: qsTrId("id-rebooting")
            font.pixelSize: Dims.l(11)
        }
    }
    Timer {
        id: delayTimer
        interval: 2000
        repeat: false
        onTriggered: langSettings.setSystemLocale(langSettings.locale(langLV.currentIndex), LanguageModel.UpdateAndReboot)
    }
}
