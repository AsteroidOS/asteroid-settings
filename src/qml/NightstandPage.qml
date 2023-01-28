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
        defaultValue: false
    }

    ConfigurationValue {
        id: nightstandUseCustomWatchface
        key: "/desktop/asteroid/nightstand/use-custom-watchface"
        defaultValue: false
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

            Item {
                width: parent.width
                height: Dims.l(20)

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: nightstandUseCustomWatchface.value = !nightstandUseCustomWatchface.value
                    Rectangle {
                        anchors.fill: parent
                        color: "white"
                        opacity: parent.containsPress ? 0.2 : 0
                    }
                }

                LabeledSwitch {
                    anchors.fill: parent
                    //% "Custom watchface"
                    text: qsTrId("id-nightstand-custom-watchface")
                    checked: nightstandUseCustomWatchface.value
                    opacity: nightstandEnabled.value ? 1.0 : 0.4
                    onCheckedChanged: nightstandUseCustomWatchface.value = checked
                }
            }

            Item {
                width: parent.width
                height: Dims.l(20)
                opacity: nightstandEnabled.value ? 1.0 : 0.4
                enabled: nightstandEnabled.value
                visible: nightstandUseCustomWatchface.value

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: layerStack.push(nightstandWatchfaceLayer)
                }

                Rectangle {
                    anchors.fill: parent
                    color: "white"
                    opacity: mouseArea.containsPress ? 0.2 : 0
                }

                Label {
                    //% "Select watchface"
                    text: qsTrId("id-nightstand-watchface")
                    font.pixelSize: Dims.l(6)
                    verticalAlignment: Text.AlignVCenter
                    height: parent.height
                    width: parent.width * 0.7143
                    wrapMode: Text.Wrap
                }
                Icon {
                    id: nextButton
                    name: "ios-arrow-dropright"
                    height: parent.height
                    width: height
                    anchors.right: parent.right
                }
            }

            Item { width: parent.width; height: Dims.l(10) }
        }
    }
}

