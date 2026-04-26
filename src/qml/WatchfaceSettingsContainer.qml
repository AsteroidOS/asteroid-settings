/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
 *               2023 - Arseniy Movshev <dodoradio@outlook.com>
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

import Nemo.Configuration 1.0
import QtQuick 2.9
import org.asteroid.controls 1.0
import org.asteroid.settings 1.0
import org.asteroid.utils 1.0

Item {
    id: container

    property Component settingsPage
    property string watchfaceName: ""
    property string watchfaceFile: ""

    ConfigurationValue {
        id: activeWatchface

        key: "/desktop/asteroid/watchface"
        defaultValue: "file:///usr/share/asteroid-launcher/watchfaces/000-default-digital.qml"
    }

    Flickable {
        id: settingsFlick

        anchors {
            top: parent.top
            topMargin: pageHeader.height
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        contentHeight: settingsColumn.height
        clip: true

        Column {
            id: settingsColumn

            width: parent.width

            Loader {
                id: settingsLoader

                width: parent.width
                height: container.height - pageHeader.height
                sourceComponent: container.settingsPage
            }

            RowSeparator {
            }

            Item {
                width: parent.width
                height: Dims.h(24)

                Column {
                    anchors.centerIn: parent

                    Icon {
                        name: "ios-trash-outline"
                        width: Dims.l(12)
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        width: Dims.l(70)
                        horizontalAlignment: Text.AlignHCenter
                        //% "Remove"
                        text: qsTrId("id-remove")
                        anchors.horizontalCenter: parent.horizontalCenter

                        font {
                            pixelSize: Dims.l(8)
                            family: "Noto Sans"
                            styleName: "SemiCondensed SemiBold"
                        }
                    }
                }

                HighlightBar {
                    onClicked: {
                        //% "Remove"
                        removeRemorse.action = qsTrId("id-remove") + " " + container.watchfaceName
                        removeRemorse.start()
                    }
                }
            }

            Item {
                width: parent.width
                height: DeviceSpecs.hasRoundScreen ? Dims.l(8) : 0
            }
        }
    }

    RemorseTimer {
        id: removeRemorse

        duration: 3000
        gaugeSegmentAmount: 8
        gaugeStartDegree: -130
        gaugeEndFromStartDegree: 265
        //% "Tap to cancel"
        cancelText: qsTrId("id-tap-to-cancel")
        onTriggered: {
            if (activeWatchface.value === container.watchfaceFile)
                activeWatchface.value = activeWatchface.defaultValue
            layerStack.pop(layerStack.currentLayer)
            WatchfaceHelper.removeWatchface(container.watchfaceName)
        }
    }

    PageHeader {
        id: pageHeader

        text: container.watchfaceName
    }
}
