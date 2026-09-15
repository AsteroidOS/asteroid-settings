/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-FileCopyrightText: 2022 Timo Könnecke <github.com/eLtMosen>
 * SPDX-FileCopyrightText: 2022 Darrel Griët <dgriet@gmail.com>
 * SPDX-FileCopyrightText: 2015 Florent Revest <revestflo@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import Nemo.Configuration
import Qt.labs.folderlistmodel
import QtQuick
import QtQuick.Effects
import org.asteroid.controls
import org.asteroid.settings
import org.asteroid.utils

Item {
    property int depth
    property var pop
    property string assetPath: "file:///usr/share/asteroid-launcher/wallpapers/"
    // User wallpaper folder (file:// URL), where a watchface's bundled
    // wallpaper is installed. From the lightweight helper singleton: a page
    // that only needs a path must not construct the store backend to get one.
    readonly property string userAssetPath: WatchfaceHelper.userAssetPath + "wallpapers/"

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

    // System and user wallpapers merged into one grid, so a watchface's bundled
    // wallpaper (installed into the user folder) appears alongside the stock
    // set. Each entry carries everything the delegate needs precomputed — the
    // displayed thumbnail and the .qml activation sibling when one exists — so
    // delegates do no per-item filesystem checks or string work while flicking.
    ListModel {
        id: unifiedModel
    }

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

    // Coalesce the two folder models' change bursts into a single rebuild, and
    // skip the rebuild when the resulting list is unchanged: the two models
    // populate asynchronously and would otherwise tear down and rebuild the
    // grid twice on every page open.
    Timer {
        id: rebuildTimer

        property var lastPaths: []

        interval: 100
        repeat: false
        onTriggered: {
            var entries = [];
            for (var i = 0; i < sysWallpaperModel.count; i++) {
                var fn = sysWallpaperModel.get(i, "fileName");
                var sysThumb = assetPath + Dims.w(50) + "/" + fn;
                entries.push({
                    "filePath": assetPath + "full/" + fn,
                    "thumbPath": FileInfo.exists(sysThumb.slice(7)) ? sysThumb : assetPath + "full/" + fn
                });
            }
            for (var j = 0; j < userWallpaperModel.count; j++) {
                var ufn = userWallpaperModel.get(j, "fileName");
                if (!FileInfo.exists((userAssetPath + "full/" + ufn).slice(7)))
                    continue;

                // User wallpapers have no pre-scaled thumbnail; the delegate's
                // sourceSize keeps their decode at cell size.
                entries.push({
                    "filePath": userAssetPath + "full/" + ufn,
                    "thumbPath": userAssetPath + "full/" + ufn
                });
            }
            var paths = entries.map(function(e) {
                return e.filePath;
            });
            if (JSON.stringify(paths) === JSON.stringify(lastPaths))
                return ;

            lastPaths = paths;
            unifiedModel.clear();
            for (var k = 0; k < entries.length; k++) {
                var qmlSibling = entries[k].filePath.replace(/\.[^.]+$/, ".qml");
                unifiedModel.append({
                    "filePath": entries[k].filePath,
                    "thumbPath": entries[k].thumbPath,
                    "qmlPath": qmlWallpapersModel.indexOf(qmlSibling) !== -1 ? qmlSibling : ""
                });
            }
            for (var m = 0; m < unifiedModel.count; m++) {
                var entry = unifiedModel.get(m);
                if (wallpaperSource.value === entry.filePath || wallpaperSource.value === entry.qmlPath) {
                    // Deferred: this timer can fire before the grid's first
                    // layout, where positioning would silently no-op.
                    var idx = m;
                    Qt.callLater(function() {
                        grid.positionViewAtIndex(idx, GridView.Center);
                    });
                    break;
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
                // The value a tap writes: the live .qml sibling when the
                // wallpaper has one, the image itself otherwise.
                readonly property string activationValue: model.qmlPath !== "" ? model.qmlPath : model.filePath
                readonly property bool selected: wallpaperSource.value === activationValue

                width: grid.cellWidth
                height: grid.cellHeight

                Image {
                    id: img

                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: model.thumbPath
                    // Decode at cell size: a full-resolution user wallpaper
                    // otherwise decodes to a multi-megabyte image per tile.
                    sourceSize.width: grid.cellWidth
                    sourceSize.height: grid.cellHeight
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: wallpaperSource.value = activationValue
                }

                Rectangle {
                    id: highlightSelection

                    anchors.fill: img
                    color: "#30000000"
                    visible: opacity
                    opacity: selected ? 0 : 1

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
                    visible: selected
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
