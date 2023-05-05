/*
 * Copyright (C) 2023 - Timo Könnecke <github.com/eLtMosen>
 * Copyright (C) 2020 - Darrel Griët <idanlcontact@gmail.com>
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
import QtQuick.Layouts 1.3
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import org.asteroid.settings 1.0
import org.nemomobile.systemsettings 1.0
import Nemo.Configuration 1.0

Item {
    TapToWake { id: tapToWake }
    TiltToWake { id: tiltToWake }
    DisplaySettings { id: displaySettings }
    ConfigurationValue {
        id: useBip
        key: "/org/asteroidos/settings/use-burn-in-protection"
        defaultValue: DeviceInfo.needsBurnInProtection
    }

    property string rowHeight: Dims.h(25)

    Flickable {
        anchors.fill: parent
        anchors.topMargin: Dims.l(10)
        anchors.bottomMargin: Dims.l(15)
        contentHeight: contentColumn.implicitHeight

        Column {
            id: contentColumn
            anchors.fill: parent

            Label {
                id: brightnessLabel
                width: parent.width
                height: Dims.l(12)
                //% "Brightness"
                text: qsTrId("id-brightness")
                font.pixelSize: Dims.l(6)
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }

            IntSelector {
                width: parent.width
                height: rowHeight
                stepSize: 10
                min: 10
                value: displaySettings.brightness
                onValueChanged: displaySettings.brightness = value
            }

            LabeledSwitch {
                height: rowHeight
                width: parent.width
                //% "Automatic brightness"
                text: qsTrId("id-automatic-brightness")
                checked: displaySettings.ambientLightSensorEnabled
                onCheckedChanged: displaySettings.ambientLightSensorEnabled = checked
            }

            LabeledSwitch {
                height: rowHeight
                width: parent.width
                //% "Always on Display"
                text: qsTrId("id-always-on-display")
                checked: displaySettings.lowPowerModeEnabled
                onCheckedChanged: displaySettings.lowPowerModeEnabled = checked
            }

            LabeledSwitch {
                height: rowHeight
                width: parent.width
                visible: DeviceInfo.needsBurnInProtection
                //% "Burn in protection"
                text: qsTrId("id-burn-in-protection")
                checked: useBip.value
                onCheckedChanged: useBip.value = checked
            }

            LabeledSwitch {
                height: rowHeight
                width: parent.width
                opacity: !tiltToWake.available ? 0.6 : 1.0
                //enabled: tiltToWake.available
                //% "Tilt-to-wake"
                text: qsTrId("id-tilt-to-wake")
                checked: tiltToWake.enabled
                onCheckedChanged: tiltToWake.enabled = checked
            }

            LabeledSwitch {
                height: rowHeight
                width: parent.width
                //% "Tap-to-wake"
                text: qsTrId("id-tap-to-wake")
                checked: tapToWake.enabled
                onCheckedChanged: tapToWake.enabled = checked
            }
        }
    }
}

