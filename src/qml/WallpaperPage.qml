import Nemo.Configuration
import Qt.labs.folderlistmodel
/*
 * SPDX-FileCopyrightText: 2022 Timo Könnecke <github.com/eLtMosen>
 * SPDX-FileCopyrightText: 2022 Darrel Griët <dgriet@gmail.com>
 * SPDX-FileCopyrightText: 2015 Florent Revest <revestflo@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Effects
import org.asteroid.controls
import org.asteroid.utils

Item {
    property int depth
    property var pop
    property string assetPath: "file:///usr/share/asteroid-launcher/wallpapers/"

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

    GridView {
        id: grid

        cellWidth: Dims.w(50)
        cellHeight: Dims.h(40)
        anchors.fill: parent

        model: FolderListModel {
            id: folderModel

            folder: assetPath + "full"
            nameFilters: ["*.jpg", "*.png", "*.svg"]
            onCountChanged: {
                var i = 0;
                while (i < folderModel.count) {
                    var fileName = folderModel.get(i, "fileName");
                    var fileBaseName = folderModel.get(i, "fileBaseName");
                    if (wallpaperSource.value === folderModel.folder + "/" + fileName | wallpaperSource.value === folderModel.folder + "/" + fileBaseName + ".qml")
                        grid.positionViewAtIndex(i, GridView.Center);

                    i = i + 1;
                }
            }
        }

        delegate: Component {
            id: fileDelegate

            Item {
                width: grid.cellWidth
                height: grid.cellHeight

                Image {
                    // Else use the full resolution wallpaper with negative impact on performance, as failsafe.

                    id: img

                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    // If a pre-scaled thumbnail file exists, use that.
                    source: FileInfo.exists((assetPath + Dims.w(50) + "/" + fileName).slice(7)) ? assetPath + Dims.w(50) + "/" + fileName : folderModel.folder + "/" + fileName
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (qmlWallpapersModel.indexOf(folderModel.folder + "/" + fileBaseName + ".qml") !== -1)
                            wallpaperSource.value = folderModel.folder + "/" + fileBaseName + ".qml";
                        else
                            wallpaperSource.value = folderModel.folder + "/" + fileName;
                    }
                }

                Rectangle {
                    id: highlightSelection

                    property bool notSelected: wallpaperSource.value !== folderModel.folder + "/" + fileName & wallpaperSource.value !== folderModel.folder + "/" + fileBaseName + ".qml"

                    anchors.fill: img
                    color: "#30000000"
                    visible: opacity
                    opacity: notSelected ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 100
                        }

                    }

                }

                Icon {
                    name: "ios-checkmark-circle"
                    height: width
                    width: parent.width * 0.3
                    visible: wallpaperSource.value === folderModel.folder + "/" + fileName | wallpaperSource.value === folderModel.folder + "/" + fileBaseName + ".qml"
                    layer.enabled: visible

                    anchors {
                        bottom: parent.bottom
                        bottomMargin: parent.height * 0.05
                        horizontalCenter: parent.horizontalCenter
                        horizontalCenterOffset: index % 2 ? -parent.height * 0.4 : parent.height * 0.38
                    }

                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#88000000"
                        shadowHorizontalOffset: 2
                        shadowVerticalOffset: 2
                        shadowBlur: 1
                        blurMax: 8
                    }

                }

            }

        }

    }

}
