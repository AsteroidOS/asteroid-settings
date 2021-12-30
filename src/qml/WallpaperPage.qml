/*
 * Copyright (C) 2021 - Timo Könnecke <github.com/eLtMosen>
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
import Qt.labs.folderlistmodel 2.1
import Nemo.Configuration 1.0
import org.asteroid.controls 1.0

Item {

    property string assetPath: "file:///usr/share/asteroid-launcher/"

    ConfigurationValue {
        id: wallpaperSource

        key: "/desktop/asteroid/background-filename"
        defaultValue: assetPath + "wallpapers/000-flatmesh.qml"
    }

    FolderListModel {
        id: qmlWallpapersModel

        folder: assetPath + "wallpapers"
        nameFilters: ["*.qml"]
    }

    GridView {
        id: grid

        cellWidth: Dims.w(50)
        cellHeight: Dims.h(40)
        anchors.fill: parent

        model: FolderListModel {
            id: folderModel

            folder: assetPath + "wallpapers"
            nameFilters: ["*.jpg"]
            onCountChanged: {
                var i = 0
                while (i < folderModel.count){
                    var fileName = folderModel.get(i, "fileName")
                    var fileBaseName = folderModel.get(i, "fileBaseName")
                    if(wallpaperSource.value === folderModel.folder + "/" + fileName |
                       wallpaperSource.value === folderModel.folder + "/" + fileBaseName + ".qml") {
                        grid.positionViewAtIndex(i, GridView.Center)
                    }
                    i = i + 1
                }
            }
        }

        delegate: Component {
            id: fileDelegate

            Item {
                width: grid.cellWidth
                height: grid.cellHeight
                Image {
                    id: img

                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: assetPath + "wallpaperpreview/" + Dims.w(100) / 2 + "/" + fileName
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if(qmlWallpapersModel.indexOf(folderModel.folder + "/" + fileBaseName + ".qml") !== -1)
                            wallpaperSource.value = folderModel.folder + "/" + fileBaseName + ".qml"
                        else
                            wallpaperSource.value = folderModel.folder + "/" + fileName
                    }
                }

                Rectangle {
                    anchors.fill: img
                    color: "#4D000000"
                    visible: wallpaperSource.value === folderModel.folder + "/" + fileName |
                             wallpaperSource.value === folderModel.folder + "/" + fileBaseName + ".qml"
                }

                Icon {
                    name: "ios-checkmark-circle"
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: parent.height * 0.05
                        right: parent.right
                        rightMargin: parent.height * 0.05

                    }
                    height: width
                    width: parent.width * 0.3
                    visible: wallpaperSource.value === folderModel.folder + "/" + fileName |
                             wallpaperSource.value === folderModel.folder + "/" + fileBaseName + ".qml"
                }
            }
        }
    }
}
