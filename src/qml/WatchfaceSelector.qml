/*
 * Copyright (C) 2023 - Arseniy Movshev <dodoradio@outlook.com>
 *               2022 - Timo Könnecke <github.com/eLtMosen>
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
    id: watchfaceSelector
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
                    if(watchface === folderModel.folder + "/" + fileName)
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
                        active: visible || (watchface === folderModel.folder + "/" + fileName)
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height)
                        height: width
                        source: folderModel.folder + "/" + fileName
                        asynchronous: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: if ((watchface === folderModel.folder + "/" + fileName) && (typeof previewQml.item.settingsPage !== "undefined")) {
				 layerStack.push(previewQml.item.settingsPage) 
			} else {
                        	watchface = folderModel.folder + "/" + fileName
			}
                    }

                    Image {
                        id: wallpaperBack

                        property string previewSizePath: "wallpapers/" + Dims.w(50)
                        property string wallpaperPreviewImg: wallpaperSource.value.replace("\wallpapers/full/g", previewSizePath).slice(0, -3) + "jpg"

                        z: 0
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        visible: opacity
                        opacity: watchface === folderModel.folder + "/" + fileName ? 1 : 0
                        source: opacity > 0 ? FileInfo.exists(wallpaperPreviewImg) ?
                                    wallpaperPreviewImg :
                                    wallpaperSource.value : ""
                        Behavior on opacity { NumberAnimation { duration: 100 } }
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
                    name: "ios-settings-outline"

                    z: 100
                    width: parent.width*0.8
                    height: width
                    visible: (watchface === folderModel.folder + "/" + fileName) && (typeof previewQml.item.settingsPage !== "undefined")
                    anchors.centerIn: parent
                    layer.enabled: visible
                    opacity: visible ? 0.4 : 0
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 2
                        verticalOffset: 2
                        radius: 8.0
                        samples: 17
                        color: "#88000000"
                    }
                }
                Rectangle {
                    id: textContainer
                    anchors { 
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        margins: parent.width*0.05
                    }
                    radius: height*0.4
                    height: parent.height*0.17
                    color: "#000000"
                    opacity: 0.6
                    visible: watchface === folderModel.folder + "/" + fileName
                    Marquee {
                        text: fileName.replace(".qml","")
                        color: "#FFFFFF"
                        anchors {
                            fill: parent
                            leftMargin: parent.width*0.05
                            rightMargin: parent.width*0.05
                        }
                        font.pixelSize: parent.height*0.7
                    }
                }
            }
        }
    }
}
