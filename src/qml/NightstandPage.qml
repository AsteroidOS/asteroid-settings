/*
 * Copyright (C) 2023 - Timo Könnecke <github.com/eLtMosen>
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

    property string rowHeight: Dims.h(25)

    Flickable {
        anchors.fill: parent
        contentHeight: onOffSettings.implicitHeight
        boundsBehavior: Flickable.DragOverBounds
        flickableDirection: Flickable.VerticalFlick
        anchors {
            topMargin: Dims.l(10)
            bottomMargin: Dims.l(15)
        }

        Item { width: parent.width; height: Dims.l(10) }

        Column {
            id: onOffSettings
            anchors.fill: parent
            LabeledSwitch {
                //% "Enable"
                text: qsTrId("id-nightstand-enable")
                width: parent.width
                height: rowHeight
                checked: nightstandEnabled.value
                onCheckedChanged: nightstandEnabled.value = checked
            }

            Column {
                width: parent.width
                opacity: nightstandEnabled.value ? 1.0 : 0.4
                enabled: nightstandEnabled.value

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200;
                        easing.type: Easing.OutQuad
                    }
                }

                Label {
                    //% "Brightness"
                    text: qsTrId("id-nightstand-brightness")
                    width: parent.width
                    height: Dims.l(12)
                    font.pixelSize: Dims.l(6)
                    verticalAlignment: Text.AlignBottom
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }

                IntSelector {
                    width: parent.width
                    height: rowHeight
                    stepSize: 10
                    value: nightstandBrightness.value
                    onValueChanged: nightstandBrightness.value = value
                }
            }

            Column {
                width: parent.width
                opacity: nightstandEnabled.value ? 1.0 : 0.4
                enabled: nightstandEnabled.value

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200;
                        easing.type: Easing.OutQuad
                    }
                }

                Label {
                    //% "Delay"
                    text: qsTrId("id-nightstand-delay")
                    width: parent.width
                    height: Dims.l(12)
                    font.pixelSize: Dims.l(6)
                    verticalAlignment: Text.AlignBottom
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }

                IntSelector {
                    width: parent.width
                    height: rowHeight
                    stepSize: 5
                    max: 30
                    unitMarker: "s"
                    value: nightstandDelay.value
                    onValueChanged: nightstandDelay.value = value
                }
            }

            Item { width: parent.width; height: Dims.h(6) }

            Item {
                width: parent.width
                height: rowHeight

                LabeledSwitch {
                    anchors.fill: parent
                    height: rowHeight
                    //% "Custom watchface"
                    text: qsTrId("id-nightstand-custom-watchface")
                    checked: nightstandUseCustomWatchface.value
                    opacity: nightstandEnabled.value ? 1.0 : 0.4
                    onCheckedChanged: nightstandUseCustomWatchface.value = checked
                    enabled: nightstandEnabled.value

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200;
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: rowHeight
                opacity: nightstandEnabled.value && nightstandUseCustomWatchface.value ? 1.0 : 0.4
                enabled: nightstandEnabled.value && nightstandUseCustomWatchface.value

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200;
                        easing.type: Easing.OutQuad
                    }
                }

                LabeledActionButton {
                    anchors.fill: parent
                    height: rowHeight
                    //% "Select watchface"
                    text: qsTrId("id-nightstand-watchface")
                    icon: "ios-arrow-dropright"
                    onClicked: function() { layerStack.push(nightstandWatchfaceLayer) }
                }
            }

            Item { width: parent.width; height: Dims.l(10) }
        }
    }
}
