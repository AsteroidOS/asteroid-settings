/*
 * Copyright (C) 2022 - Ed Beroset <github.com/beroset>
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

import QtQuick 2.15
import QtQuick.Layouts 1.3
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import org.asteroid.settings 1.0
import org.nemomobile.systemsettings 1.0
import Nemo.Configuration 1.0

Item {
    property alias nightstandwatchface: watchfaceNightstandSource.value
    property alias regularwatchface: watchfaceSource.value
    property string assetPath: "file:///usr/share/asteroid-launcher/"

    ConfigurationValue {
        id: nightstandTracksRegularWatchface
        key: "/desktop/asteroid/nightstand/samewatchface"
        defaultValue: true
    }

    ConfigurationValue {
        id: watchfaceSource
        key: "/desktop/asteroid/watchface"
        defaultValue: assetPath + "watchfaces/000-default-digital.qml"
    }

    ConfigurationValue {
        id: watchfaceNightstandSource
        key: "/desktop/asteroid/nightstand/watchface"
        defaultValue: assetPath + "watchfaces/000-default-digital.qml"
    }

    ConfigurationValue {
        id: nightstandBrightness
        key: "/desktop/asteroid/nightstand/brightness"
        defaultValue: 30
    }

    ConfigurationValue {
        id: nightstandDelay
        key: "/desktop/asteroid/nightstand/delay"
        defaultValue: 5
    }

    ConfigurationValue {
        id: nightstandEnabled
        key: "/desktop/asteroid/nightstand/enabled"
        defaultValue: true
    }

    PageHeader {
        id: title
        text: qsTrId("id-nightstand-page")
    }

    Flickable {
        anchors.fill: parent
        contentHeight: onOffSettings.implicitHeight
        boundsBehavior: Flickable.DragOverBounds
        flickableDirection: Flickable.VerticalFlick
        anchors.margins: Dims.l(15)

        Column {
            id: onOffSettings
            anchors.fill: parent
            LabeledSwitch {
                //% "Enable"
                text: qsTrId("id-nightstand-enable")
                width: parent.width
                height: Dims.l(20)
                checked: nightstandEnabled.value
                onCheckedChanged: nightstandEnabled.value = checked
            }

            Column {
                width: parent.width
                opacity: nightstandEnabled.value ? 1.0 : 0.4
		enabled: nightstandEnabled.value
                Label {
                    //% "Brightness"
                    text: qsTrId("id-nightstand-brightness")
                    font.pixelSize: Dims.l(6)
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                }
                IntSelector {
                    width: parent.width
                    height: Dims.l(20)
                    stepSize: 10
                    value: nightstandBrightness.value
                    onValueChanged: nightstandBrightness.value = value
                }
            }

            Column {
                width: parent.width
                opacity: nightstandEnabled.value ? 1.0 : 0.4
		enabled: nightstandEnabled.value
                Label {
                    //% "Delay"
                    text: qsTrId("id-nightstand-delay")
                    font.pixelSize: Dims.l(6)
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                }
                IntSelector {
                    width: parent.width
                    height: Dims.l(20)
                    stepSize: 5
                    max: 30
                    unitMarker: "s"
                    value: nightstandDelay.value
                    onValueChanged: nightstandDelay.value = value
                }
            }

            LabeledSwitch {
                //% "Use Custom Watchface"
                text: qsTrId("id-nightstand-custom-watchface")
                width: parent.width
                height: Dims.l(20)
                opacity: nightstandEnabled.value ? 1.0 : 0.4
		enabled: nightstandEnabled.value
                checked: nightstandTracksRegularWatchface.value
                onCheckedChanged: {
                    if (checked) {
                        layerStack.push(nightstandWatchfaceLayer)
                    } else {
                        nightstandwatchface = regularwatchface
                    }
                }
            }

            Item { width: parent.width; height: Dims.l(10) }
        }
    }
}

