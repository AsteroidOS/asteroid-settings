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
import Nemo.Time 1.0

Item {
    id: watchfaceSelector

    property bool storeAvailable: false
    property string deletingName: ""

    readonly property var previewSizes: [112, 128, 144, 160, 182]
    readonly property int idealPreviewSize: Math.round(Dims.w(40))
    readonly property int previewSize: {
        let best = previewSizes[0];
        let minDiff = Math.abs(best - idealPreviewSize);
        for (let i = 1, n = previewSizes.length; i < n; ++i) {
            const size = previewSizes[i];
            const diff = Math.abs(size - idealPreviewSize);
            if (diff < minDiff || (diff === minDiff && size > best)) {
                minDiff = diff;
                best = size;
            }
        }
        return best;
    }

    ConfigurationValue {
        id: activeWatchface
        key: "/desktop/asteroid/watchface"
        defaultValue: "file:///usr/share/asteroid-launcher/watchfaces/000-default-digital.qml"
    }

    // ── Network probe
    
    Component.onCompleted: probeConnection()

    function probeConnection() {
        var xhr = new XMLHttpRequest()
        xhr.open("HEAD", "https://api.github.com")
        xhr.timeout = 6000
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            watchfaceSelector.storeAvailable = (xhr.status > 0 && xhr.status < 500)
        }
        xhr.send()
    }

    // ── Watchface store component

    Component {
        id: watchfaceStoreComponent
        WatchfaceStorePage {}
    }

    // ── Unified model from system + user watchface folders

    ListModel { id: unifiedModel }

    FolderListModel {
        id: folderModel
        folder: assetPath + "watchfaces"
        nameFilters: ["*.qml"]
        onCountChanged: rebuildTimer.restart()
    }

    FolderListModel {
        id: userFolderModel
        folder: "file://" + WatchfaceHelper.userWatchfacePath()
        nameFilters: ["*.qml"]
        onCountChanged: rebuildTimer.restart()
    }

    Timer {
        id: rebuildTimer
        interval: 0
        repeat: false
        onTriggered: _rebuildUnified()
    }

    function _rebuildUnified() {
        unifiedModel.clear()
        var i, fn
        for (i = 0; i < folderModel.count; i++) {
            fn = folderModel.get(i, "fileName")
            unifiedModel.append({ fileName: fn, filePath: assetPath + "watchfaces/" + fn, isUser: false })
        }
        for (i = 0; i < userFolderModel.count; i++) {
            fn = userFolderModel.get(i, "fileName")
            unifiedModel.append({ fileName: fn, filePath: "file://" + WatchfaceHelper.userWatchfacePath() + fn, isUser: true })
        }
        for (i = 0; i < unifiedModel.count; i++) {
            if (watchface === unifiedModel.get(i).filePath) {
                grid.positionViewAtIndex(i, GridView.Center)
                break
            }
        }
    }

    // ── Removal remorse timer

RemorseTimer {
        id: deleteRemorse

        property string watchfaceName: ""

        duration: 3000
        gaugeSegmentAmount: 8
        gaugeStartDegree: -130
        gaugeEndFromStartDegree: 265
        //% "Tap to cancel"
        cancelText: qsTrId("id-tap-to-cancel")

        onTriggered: {
            var targetPath = WatchfaceHelper.userAssetPath() + "watchfaces/" + watchfaceName + ".qml"
            if (activeWatchface.value === targetPath)
                activeWatchface.value = activeWatchface.defaultValue
            WatchfaceHelper.removeWatchface(watchfaceName)
            watchfaceSelector.deletingName = ""
        }

        onCancelled: watchfaceSelector.deletingName = ""
    }

    // ── Watchface grid

    GridView {
        id: grid
        cellWidth: Dims.w(50)
        cellHeight: Dims.h(45)
        anchors.fill: parent

        model: unifiedModel

        Item { id: burnInProtectionManager; property int leftOffset; property int rightOffset; property int topOffset; property int bottomOffset; property int widthOffset; property int heightOffset }
        WallClock { id: wallClock; enabled: true; updateFrequency: WallClock.Second }
        QtObject { id: localeManager; property string changesObserver: "" }

        delegate: Component {
            Item {
                width: grid.cellWidth
                height: grid.cellHeight
                
                property bool _pressActive: false
                property bool _scrollCancelled: false
                property bool _wasDeleting: false
                readonly property bool isActive: watchface === model.filePath
                
                Rectangle {
                    id: pressCircle
                    width: Dims.l(40)
                    height: width
                    radius: width
                    anchors.centerIn: parent
                    color: "#000000"
                    opacity: isActive ? 0.2 : 0.0
                    
                    NumberAnimation { id: pressAnim;   target: pressCircle; property: "opacity"; to: 0.5; duration: 800; easing.type: Easing.Linear }
                    NumberAnimation { id: releaseAnim; target: pressCircle; property: "opacity"; duration: 150; easing.type: Easing.OutQuad }
                }
                
                onIsActiveChanged: {
                    if (_pressActive) return
                        pressAnim.stop()
                        releaseAnim.stop()
                        releaseAnim.from = pressCircle.opacity
                        releaseAnim.to = isActive ? 0.2 : 0.0
                        releaseAnim.start()
                }
                
                Connections {
                    target: watchfaceSelector
                    function onDeletingNameChanged() {
                        var thisName = model.fileName.slice(0, -4)
                        if (watchfaceSelector.deletingName === thisName) {
                            _wasDeleting = true
                        } else if (_wasDeleting) {
                            _wasDeleting = false
                            pressAnim.stop()
                            releaseAnim.from = pressCircle.opacity
                            releaseAnim.to = isActive ? 0.2 : 0.0
                            releaseAnim.start()
                        }
                    }
                }
                
                Timer {
                    id: selectorHoldTimer
                    interval: 800
                    repeat: false
                    onTriggered: {
                        if (!model.isUser) {
                            pressAnim.stop()
                            releaseAnim.from = pressCircle.opacity
                            releaseAnim.to = isActive ? 0.2 : 0.0
                            releaseAnim.start()
                            return
                        }
                        watchfaceSelector.deletingName = model.fileName.slice(0, -4)
                        deleteRemorse.watchfaceName = model.fileName.slice(0, -4)
                        //% "Remove"
                        deleteRemorse.action = qsTrId("id-remove") + " " + model.fileName.slice(0, -4)
                        deleteRemorse.start()
                    }
                }
                
                Rectangle {
                    id: maskArea
                    width: Dims.l(40)
                    height: width
                    anchors.centerIn: parent
                    color: "transparent"
                    radius: DeviceSpecs.hasRoundScreen ? width : Dims.l(3)
                    clip: true
                    
                    Image {
                        id: previewPng
                        readonly property string sysPreviewImg: assetPath + "watchfaces-preview/" + previewSize + "/" + model.fileName.slice(0, -4) + ".png"
                        readonly property string userPreviewImg: WatchfaceHelper.userAssetPath() + "watchfaces-preview/" + previewSize + "/" + model.fileName.slice(0, -4) + ".png"
                        readonly property string cachePreviewImg: "file://" + WatchfaceHelper.cachePath() + previewSize + "/" + model.fileName.slice(0, -4) + ".png"
                        readonly property string previewImg: FileInfo.exists(sysPreviewImg) ? sysPreviewImg : FileInfo.exists(userPreviewImg) ? userPreviewImg : cachePreviewImg
                        property bool previewExists: FileInfo.exists(sysPreviewImg) || FileInfo.exists(userPreviewImg) || FileInfo.exists(cachePreviewImg)
                        z: 1
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height)
                        height: width
                        source: previewExists ? previewImg : ""
                        asynchronous: true
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                    }
                    
                    Loader {
                        id: previewQml
                        z: 2
                        visible: !previewPng.previewExists
                        active: visible
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height)
                        height: width
                        source: model.filePath
                        asynchronous: true
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        property real startX: 0
                        property real startY: 0
                        
                        onPressed: {
                            startX = mouse.x
                            startY = mouse.y
                            _scrollCancelled = false
                            _pressActive = true
                            pressAnim.stop()
                            releaseAnim.stop()
                            pressAnim.from = pressCircle.opacity
                            pressAnim.start()
                            selectorHoldTimer.restart()
                        }
                        
                        onPositionChanged: {
                            if (_scrollCancelled) return
                                var dx = Math.abs(mouse.x - startX)
                                var dy = Math.abs(mouse.y - startY)
                                if (dx > Dims.l(2) || dy > Dims.l(2)) {
                                    _scrollCancelled = true
                                    _pressActive = false
                                    selectorHoldTimer.stop()
                                    pressAnim.stop()
                                    releaseAnim.from = pressCircle.opacity
                                    releaseAnim.to = isActive ? 0.2 : 0.0
                                    releaseAnim.start()
                                    mouse.accepted = false
                                }
                        }
                        
                        onReleased: {
                            if (_scrollCancelled) return
                                selectorHoldTimer.stop()
                                pressAnim.stop()
                                if (watchfaceSelector.deletingName === "")
                                    watchface = model.filePath
                                    releaseAnim.from = pressCircle.opacity
                                    releaseAnim.to = watchface === model.filePath ? 0.2 : 0.0
                                    releaseAnim.start()
                                    _pressActive = false
                                    _scrollCancelled = false
                        }
                        
                        onCanceled: {
                            selectorHoldTimer.stop()
                            pressAnim.stop()
                            _pressActive = false
                            _scrollCancelled = false
                            releaseAnim.from = pressCircle.opacity
                            releaseAnim.to = isActive ? 0.2 : 0.0
                            releaseAnim.start()
                        }
                    }
                    
                    Image {
                        id: wallpaperBack
                        property string previewSizePath: "wallpapers/" + Dims.w(50)
                        property string wallpaperPreviewImg: wallpaperSource.value.replace("\\wallpapers/full\\", previewSizePath).slice(0, -3) + "jpg"
                        z: 0
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        visible: opacity
                        opacity: watchface === model.filePath ? 1 : 0
                        source: opacity > 0 ? FileInfo.exists(wallpaperPreviewImg) ? wallpaperPreviewImg : wallpaperSource.value : ""
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }
                    
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
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
                    visible: watchface === model.filePath
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: DeviceSpecs.hasRoundScreen ? -parent.height * .03 : -parent.height * .08
                        horizontalCenter: parent.horizontalCenter
                        horizontalCenterOffset: index % 2 ?
                        (DeviceSpecs.hasRoundScreen ? -parent.height * .45 : -parent.height * .40) :
                        (DeviceSpecs.hasRoundScreen ?  parent.height * .45 :  parent.height * .40)
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

        // ── "Get More" footer

        footer: Column {
            width: grid.width
            
            Item { width: parent.width; height: Dims.l(4) }
            
            RowSeparator {}
            
            Item {
                width: parent.width
                height: Dims.h(32)
                opacity: watchfaceSelector.storeAvailable ? 1.0 : 0.45
                
                Column {
                    anchors.centerIn: parent
                  
                    Icon {
                        name: "ios-cloud-download-outline"
                        width: Dims.l(12)
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Label {
                        width: Dims.l(70)
                        horizontalAlignment: Text.AlignHCenter                        
                        text: watchfaceSelector.storeAvailable ?
                        //% "Get More Watchfaces"
                        qsTrId("id-get-more-watchfaces") :
                        //% "Connect to get more watchfaces"
                        qsTrId("id-connect-for-watchfaces")
                        font { pixelSize: Dims.l(8); family: "Noto Sans"; styleName: "SemiCondensed SemiBold" }
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                
                HighlightBar {
                    enabled: watchfaceSelector.storeAvailable
                    onClicked: layerStack.push(watchfaceStoreComponent, { assetPath: assetPath, previewSize: watchfaceSelector.previewSize })
                }
            }
        }
    }
}
