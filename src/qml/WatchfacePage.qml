/*
 * Copyright (C) 2022 - Timo Könnecke <github.com/eLtMosen>
 *               2022 - Darrel Griët <dgriet@gmail.com>
 *               2015 - Florent Revest <revestflo@gmail.com>
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
import QtGraphicalEffects 1.12
import Qt.labs.folderlistmodel 2.1
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import Nemo.Configuration 1.0
import Nemo.Time 1.0

Item {

    property alias displayAmbient: compositor.displayAmbient
    property string assetPath: "file:///usr/share/asteroid-launcher/"

    ConfigurationValue {
        id: watchfaceSource

        key: "/desktop/asteroid/watchface"
        defaultValue: assetPath + "watchfaces/000-default-digital.qml"
    }

    ConfigurationValue {
        id: wallpaperSource

        key: "/desktop/asteroid/background-filename"
    }

    ConfigurationValue {
        id: use12H

        key: "/org/asteroidos/settings/use-12h-format"
        defaultValue: false
    }

    GridView {
        id: grid

        cellWidth: Dims.w(50)
        cellHeight: Dims.h(40)
        anchors.fill: parent

        model: FolderListModel {
            id: folderModel
            folder: assetPath + "watchfaces"
            nameFilters: ["*.qml"]
            onCountChanged: {
                var i = 0
                while (i < folderModel.count){
                    var fileName = folderModel.get(i, "fileName")
                    if(watchfaceSource.value === folderModel.folder + "/" + fileName)
                        grid.positionViewAtIndex(i, GridView.Center)

                    i = i+1
                }
            }
        }

        Item {
            id: burnInProtectionManager

            property int leftOffset
            property int rightOffset
            property int topOffset
            property int bottomOffset
            property int widthOffset
            property int heightOffset
        }

        QtObject {
            id: compositor

            property bool displayAmbient: false
        }

        WallClock {
            id: wallClock

            enabled: true
            updateFrequency: WallClock.Second
        }

        QtObject {
            id: localeManager

            property string changesObserver: ""
        }

        delegate: Component {

            Item {
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    id: maskArea

                    width: Dims.w(40)
                    height: grid.cellHeight
                    anchors.centerIn: parent
                    color: "transparent"
                    radius: DeviceInfo.hasRoundScreen ?
                                width :
                                Dims.w(3)
                    clip: true

                    Image {
                        id: previewPng

                        property string previewImg: (assetPath + "watchfaces-preview/" + Dims.w(40) + "/" + fileName).slice(0, -4) + ".png"
                        property bool previewExists: FileInfo.exists(previewImg)

                        z: 1
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height)
                        height: width
                        source: !previewExists ? "" : previewImg
                        asynchronous: true
                    }

                    Loader {
                        id: previewQml

                        z: 2
                        visible: !previewPng.previewExists
                        active: visible
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height)
                        height: width
                        source: folderModel.folder + "/" + fileName
                        asynchronous: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: watchfaceSource.value = folderModel.folder + "/" + fileName
                    }

                    Image {
                        id: wallpaperBack

                        property string previewSizePath: "wallpapers/" + Dims.w(50)
                        property string wallpaperPreviewImg: wallpaperSource.value.replace("\wallpapers/full/g", previewSizePath).slice(0, -3) + "jpg"

                        z: 0
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        visible: opacity
                        opacity: watchfaceSource.value === folderModel.folder + "/" + fileName ? 1 : 0
                        source: FileInfo.exists(wallpaperPreviewImg) ?
                                    wallpaperPreviewImg :
                                    wallpaperSource.value
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource:
                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(wallpaperBack.width, wallpaperBack.height)
                                height: width
                                radius: maskArea.radius
                            }
                    }
                }

                Icon {
                    name: "ios-checkmark-circle"

                    z: 100
                    width: parent.width * .3
                    height: width
                    visible: watchfaceSource.value === folderModel.folder + "/" + fileName
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: DeviceInfo.hasRoundScreen ?
                                          -parent.height * .03 :
                                          -parent.height * .08
                        horizontalCenter: parent.horizontalCenter
                        horizontalCenterOffset: index % 2 ?
                                                    DeviceInfo.hasRoundScreen ?
                                                        -parent.height * .45 :
                                                        -parent.height * .40 :
                                                        DeviceInfo.hasRoundScreen ?
                                                            parent.height * .45 :
                                                            parent.height * .40
                    }

                    layer.enabled: visible
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 2
                        verticalOffset: 2
                        radius: 8.0
                        samples: 17
                        color: "#88000000"
                    }
                }
            }
        }
    }
}
