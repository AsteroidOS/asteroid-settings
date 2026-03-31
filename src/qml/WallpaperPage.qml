/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/eLtMosen>
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
import Nemo.Configuration 1.0
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import org.asteroid.settings 1.0

Item {

    property string assetPath: "file:///usr/share/asteroid-launcher/wallpapers/"
    readonly property string userAssetPath: WatchfaceHelper.userAssetPath() + "wallpapers/"

    ConfigurationValue {
        id: wallpaperSource
        key: "/desktop/asteroid/background-filename"
        defaultValue: assetPath + "full/000-flatmesh.qml"
    }

    FolderListModel {
        id: qmlWallpapersModel
        folder: assetPath + "full"
        nameFilters: ["*.qml"]
    }

    ListModel { id: unifiedModel }

    FolderListModel {
        id: sysWallpaperModel
        folder: assetPath + "full"
        nameFilters: ["*.jpg", "*.png", "*.svg"]
        onCountChanged: rebuildTimer.restart()
    }

    FolderListModel {
        id: userWallpaperModel
        folder: userAssetPath + "full"
        nameFilters: ["*.jpg", "*.png", "*.svg"]
        onCountChanged: rebuildTimer.restart()
    }

    Timer {
        id: rebuildTimer
        interval: 100
        repeat: false
        onTriggered: {
            unifiedModel.clear()
            var i, fn, fb
            for (i = 0; i < sysWallpaperModel.count; i++) {
                fn = sysWallpaperModel.get(i, "fileName")
                fb = sysWallpaperModel.get(i, "fileBaseName")
                unifiedModel.append({ fileName: fn, fileBaseName: fb,
                    filePath: assetPath + "full/" + fn, isUser: false })
            }
            for (i = 0; i < userWallpaperModel.count; i++) {
                fn = userWallpaperModel.get(i, "fileName")
                fb = userWallpaperModel.get(i, "fileBaseName")
                var fullPath = (userAssetPath + "full/" + fn).slice(7)
                if (!FileInfo.exists(fullPath)) continue
                    unifiedModel.append({ fileName: fn, fileBaseName: fb,
                        filePath: userAssetPath + "full/" + fn, isUser: true })
            }
            for (i = 0; i < unifiedModel.count; i++) {
                var entry = unifiedModel.get(i)
                if (wallpaperSource.value === entry.filePath ||
                    wallpaperSource.value === entry.filePath.replace(/\.[^.]+$/, ".qml")) {
                    grid.positionViewAtIndex(i, GridView.Center)
                    break
                    }
            }
        }
    }

    GridView {
        id: grid

        cellWidth: Dims.w(50)
        cellHeight: Dims.h(40)
        anchors.fill: parent

        model: unifiedModel

        delegate: Component {
            id: fileDelegate

            Item {
                width: grid.cellWidth
                height: grid.cellHeight

                Image {
                    id: img

                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: {
                        var sysThumb = (assetPath + Dims.w(50) + "/" + model.fileName).slice(7)
                        if (!model.isUser && FileInfo.exists(sysThumb))
                            return assetPath + Dims.w(50) + "/" + model.fileName
                        return model.filePath
                    }
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var qmlPath = model.filePath.replace(/\.[^.]+$/, ".qml")
                        if (!model.isUser && qmlWallpapersModel.indexOf(qmlPath) !== -1)
                            wallpaperSource.value = qmlPath
                        else
                            wallpaperSource.value = model.filePath
                    }
                }

                Rectangle {
                    id: highlightSelection

                    property bool notSelected: wallpaperSource.value !== model.filePath &&
                        wallpaperSource.value !== model.filePath.replace(/\.[^.]+$/, ".qml")

                    anchors.fill: img
                    color: "#30000000"
                    visible: opacity
                    opacity: notSelected ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                }

                Icon {
                    name: "ios-checkmark-circle"
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: parent.height * 0.05
                        horizontalCenter: parent.horizontalCenter
                        horizontalCenterOffset: index % 2 ?
                                                    -parent.height * 0.4 :
                                                    parent.height * 0.38
                    }
                    height: width
                    width: parent.width * 0.3
                    visible: wallpaperSource.value === model.filePath ||
                             wallpaperSource.value === model.filePath.replace(/\.[^.]+$/, ".qml")

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
