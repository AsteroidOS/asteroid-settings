/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
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
    id: storePage

    property string assetPath: "file:///usr/share/asteroid-launcher/"
    property int previewSize: 128

    property bool loadingCatalog: true
    property string downloadingName: ""
    property bool restartPending: false
    property int cacheVersion: 0
    property int _pendingFiles: 0
    property int _inFlightXhrs: 0
    property var _pendingPreviews: ({})
    property string deletingName: ""
    property string installingName: ""
    property string failedName: ""
    property bool _restartFired: false

    readonly property string _cacheBase: WatchfaceHelper.cachePath()
    readonly property string _catalogCache: WatchfaceHelper.cachePath() + "catalog.json"
    readonly property string _apiBase: "https://api.github.com/repos/AsteroidOS/unofficial-watchfaces/contents/"
    readonly property string _rawBase: "https://raw.githubusercontent.com/AsteroidOS/unofficial-watchfaces/master/"

    ConfigurationValue {
        id: activeWatchface
        key: "/desktop/asteroid/watchface"
        defaultValue: "file:///usr/share/asteroid-launcher/watchfaces/000-default-digital.qml"
    }

    ListModel { id: storeModel }

    Component.onCompleted: {
        var cached = WatchfaceHelper.readFile(_catalogCache)
        if (cached) {
            try {
                loadingCatalog = false
                _addCommunityWatchfaces(JSON.parse(cached))
            } catch(e) {
                _fetchCatalog()
            }
        } else {
            _fetchCatalog()
        }
    }

    // ── Grid

    GridView {
        id: storeGrid
        anchors {
            top: parent.top
            // ── Margin to offset list from PageHeader
            topMargin: title.height
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        cellWidth: Dims.w(50)
        cellHeight: Dims.h(45)

        model: storeModel

        delegate: Item {
            width: storeGrid.cellWidth
            height: storeGrid.cellHeight
            
            property bool _pressActive: false
            property bool _scrollCancelled: false
            property bool _wasDeleting: false
            readonly property bool isInstalling: storePage.installingName === model.name
            
            onIsInstallingChanged: {
                if (!isInstalling && model.isInstalled)
                    bumpAnim.start()
            }
            
            Rectangle {
                id: stateBg
                width: Dims.l(40)
                height: width
                radius: width
                anchors.centerIn: parent
                color: model.isInstalled ? "#44ff88" : "#000000"
                opacity: model.isInstalled ? 0.5 : 0.2
                
                NumberAnimation { id: opacityAnim; target: stateBg; property: "opacity"; easing.type: Easing.OutQuad }
                ColorAnimation  { id: colorAnim;   target: stateBg; property: "color";   easing.type: Easing.OutQuad }
                
                SequentialAnimation {
                    id: bumpAnim
                    NumberAnimation { target: stateBg; property: "opacity"; to: 0.65; duration: 120; easing.type: Easing.OutQuad }
                    NumberAnimation { target: stateBg; property: "opacity"; to: 0.5;  duration: 200; easing.type: Easing.InQuad }
                }
                
                SequentialAnimation {
                    id: failAnim
                    ColorAnimation  { target: stateBg; property: "color"; to: "#ff4444"; duration: 200 }
                    PauseAnimation  { duration: 1200 }
                    ColorAnimation  { target: stateBg; property: "color"; to: "#000000"; duration: 400 }
                    NumberAnimation { target: stateBg; property: "opacity"; to: 0.2; duration: 300 }
                    onStopped: storePage.failedName = ""
                }
            }
            
            Connections {
                target: storePage
                function onFailedNameChanged() {
                    if (storePage.failedName === model.name) failAnim.start()
                }
                function onDeletingNameChanged() {
                    if (model.isInstalled) {
                        if (storePage.deletingName === model.name) {
                            _wasDeleting = true
                        } else if (_wasDeleting) {
                            _wasDeleting = false
                            opacityAnim.stop()
                            opacityAnim.from = stateBg.opacity
                            opacityAnim.to = 0.5
                            opacityAnim.duration = 200
                            opacityAnim.start()
                        }
                    }
                }
            }
            
            Timer {
                id: storeHoldTimer
                interval: 800
                repeat: false
                onTriggered: {
                    if (!model.isInstalled) return
                        storePage.deletingName = model.name
                        removeRemorse.watchfaceName = model.name
                        //% "Remove"
                        removeRemorse.action = qsTrId("id-remove") + " " + model.name
                        removeRemorse.start()
                }
            }
            
            Rectangle {
                id: storeItemMask
                width: Dims.l(40)
                height: width
                anchors.centerIn: parent
                color: "transparent"
                radius: DeviceSpecs.hasRoundScreen ? width : Dims.l(3)
                clip: true
                
                Image {
                    id: storePreview
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    opacity: model.isInstalled ? 1.0 : 0.7
                    
                    source: {
                        var _cv = storePage.cacheVersion
                        if (model.isInstalled)
                            return WatchfaceHelper.userAssetPath() + "watchfaces-preview/" + storePage.previewSize + "/" + model.name + ".png"
                            var cacheDest = storePage._cacheBase + storePage.previewSize + "/" + model.name + ".png"
                            return FileInfo.exists(cacheDest) ? "file://" + cacheDest : ""
                    }
                    
                    Component.onCompleted: {
                        if (!model.isInstalled)
                            storePage._ensurePreview(model.name)
                    }
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
                        bumpAnim.stop()
                        failAnim.stop()
                        opacityAnim.stop()
                        colorAnim.stop()
                        if (model.isInstalled) {
                            opacityAnim.from = stateBg.opacity
                            opacityAnim.to = 0.0
                            opacityAnim.duration = 800
                            opacityAnim.easing.type = Easing.Linear
                            opacityAnim.start()
                            storeHoldTimer.restart()
                        } else if (storePage.downloadingName === "") {
                            colorAnim.from = stateBg.color
                            colorAnim.to = "#44ff88"
                            colorAnim.duration = 300
                            colorAnim.start()
                            opacityAnim.from = stateBg.opacity
                            opacityAnim.to = 0.35
                            opacityAnim.duration = 300
                            opacityAnim.easing.type = Easing.OutQuad
                            opacityAnim.start()
                        }
                    }
                    
                    onPositionChanged: {
                        if (_scrollCancelled) return
                            var dx = Math.abs(mouse.x - startX)
                            var dy = Math.abs(mouse.y - startY)
                            if (dx > Dims.l(2) || dy > Dims.l(2)) {
                                _scrollCancelled = true
                                _pressActive = false
                                storeHoldTimer.stop()
                                opacityAnim.stop()
                                colorAnim.stop()
                                colorAnim.from = stateBg.color
                                colorAnim.to = model.isInstalled ? "#44ff88" : "#000000"
                                colorAnim.duration = 150
                                colorAnim.start()
                                opacityAnim.from = stateBg.opacity
                                opacityAnim.to = model.isInstalled ? 0.5 : 0.2
                                opacityAnim.duration = 150
                                opacityAnim.easing.type = Easing.OutQuad
                                opacityAnim.start()
                                mouse.accepted = false
                            }
                    }
                    
                    onReleased: {
                        if (_scrollCancelled) return
                        storeHoldTimer.stop()
                        _pressActive = false
                        _scrollCancelled = false
                        if (!model.isInstalled && storePage.downloadingName === "") {
                            // keep animating toward full green — do not stop
                            colorAnim.stop()
                            opacityAnim.stop()
                            colorAnim.from = stateBg.color
                            colorAnim.to = "#44ff88"
                            colorAnim.duration = 300
                            colorAnim.start()
                            opacityAnim.from = stateBg.opacity
                            opacityAnim.to = 0.5
                            opacityAnim.duration = 300
                            opacityAnim.easing.type = Easing.OutQuad
                            opacityAnim.start()
                            storePage._startDownload(model.name)
                        } else if (model.isInstalled && storePage.deletingName === "") {
                            opacityAnim.stop()
                            opacityAnim.from = stateBg.opacity
                            opacityAnim.to = 0.5
                            opacityAnim.duration = 200
                            opacityAnim.easing.type = Easing.OutQuad
                            opacityAnim.start()
                        }
                    }
                    
                    onCanceled: {
                        storeHoldTimer.stop()
                        _pressActive = false
                        _scrollCancelled = false
                        opacityAnim.stop()
                        colorAnim.stop()
                        colorAnim.from = stateBg.color
                        colorAnim.to = model.isInstalled ? "#44ff88" : "#000000"
                        colorAnim.duration = 200
                        colorAnim.start()
                        opacityAnim.from = stateBg.opacity
                        opacityAnim.to = model.isInstalled ? 0.5 : 0.2
                        opacityAnim.duration = 200
                        opacityAnim.easing.type = Easing.OutQuad
                        opacityAnim.start()
                    }
                }
                
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(storePreview.width, storePreview.height)
                        height: width
                        radius: storeItemMask.radius
                    }
                }
            }
            
            Icon {
                name: "ios-checkmark-circle"
                z: 100
                width: parent.width * .3
                height: width
                visible: activeWatchface.value === WatchfaceHelper.userAssetPath() + "watchfaces/" + model.name + ".qml"
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

        // ── Footer: restart + refresh

        footer: Column {
            width: storeGrid.width
            
            Item { width: parent.width; height: Dims.l(4) }

            RowSeparator {}

            Item {
                width: parent.width
                height: Dims.h(32)

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
                        //% "Refresh store"
                        text: qsTrId("id-refresh-store")
                        font { pixelSize: Dims.l(8); family: "Noto Sans"; styleName: "SemiCondensed SemiBold" }
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                HighlightBar { onClicked: _fetchCatalog() }
            }

            RowSeparator {}
            
            Item {
                width: parent.width
                height: Dims.h(32)

                Column {
                    anchors.centerIn: parent
                    spacing: Dims.l(1)

                    Icon {
                        name: "ios-refresh"
                        width: Dims.l(12)
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        width: Dims.l(70)
                        horizontalAlignment: Text.AlignHCenter                        
                        //% "Restart launcher"
                        text: qsTrId("id-restart-launcher")
                        font { pixelSize: Dims.l(8); family: "Noto Sans"; styleName: "SemiCondensed SemiBold" }
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                
                HighlightBar { onClicked: restartRemorse.start() }
            }
        }
    }

    // ── Loading indicator

    Label {
        anchors.centerIn: parent
        visible: loadingCatalog && storeModel.count === 0
        //% "Loading..."
        text: qsTrId("id-loading")
        font { pixelSize: Dims.l(6); styleName: "Light" }
        color: "#80ffffff"
    }
    
    // ── Page header
    
    PageHeader {
        id: title
        //% "Watchface Store"
        text: qsTrId("id-watchface-store")
    }

    // ── Removal remorse timer

    RemorseTimer {
        id: removeRemorse
        
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
                if (WatchfaceHelper.removeWatchface(watchfaceName)) {
                    for (var i = 0; i < storeModel.count; i++) {
                        if (storeModel.get(i).name === watchfaceName) {
                            storeModel.setProperty(i, "isInstalled", false)
                            break
                        }
                    }
                }
                storePage.deletingName = ""
        }
        
        onCancelled: storePage.deletingName = ""
    }
    
    // ── Launcher restart remorse timer with full black cut off before restart
    
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: _restartFired ? 0.92 : restartRemorse.opacity * 0.92
        visible: opacity > 0
    }
    
    RemorseTimer {
        id: restartRemorse
        duration: 4000
        gaugeSegmentAmount: 6
        gaugeStartDegree: -130
        gaugeEndFromStartDegree: 265
        //% "Restart launcher"
        action: qsTrId("id-restart-launcher")
        //% "Tap to cancel"
        cancelText: qsTrId("id-tap-to-cancel")
        onTriggered: {
            storePage._restartFired = true
            WatchfaceHelper.restartSession()
        }
    }

    // ── WatchfaceHelper connections

    Connections {
        target: WatchfaceHelper

        function onDownloadComplete(destPath, success) {
            if (destPath.startsWith(storePage._cacheBase)) {
                if (!success) {
                    var cacheName = destPath.split("/").pop().replace(".png", "")
                    for (var i = 0; i < storeModel.count; i++) {
                        if (storeModel.get(i).name === cacheName) { storeModel.remove(i); break }
                    }
                } else {
                    storePage.cacheVersion++
                }
                return
            }
            if (storePage.downloadingName !== "") {
                if (!success) {
                    console.warn("WatchfaceStorePage: download failed:", destPath)
                    if (destPath.endsWith(".qml"))
                        storePage.failedName = storePage.downloadingName
                }
                storePage._pendingFiles--
                storePage._checkInstallComplete()
            }
        }
    }

    // ── Private functions

    function _fetchCatalog() {
        loadingCatalog = true
        storeModel.clear()
        var xhr = new XMLHttpRequest()
        xhr.open("GET", _apiBase)
        xhr.timeout = 10000
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            loadingCatalog = false
            if (xhr.status !== 200) {
                console.warn("WatchfaceStorePage: catalog fetch failed, status", xhr.status)
                return
            }
            try {
                var text = xhr.responseText
                WatchfaceHelper.writeFile(_catalogCache, text)
                _addCommunityWatchfaces(JSON.parse(text))
            } catch(e) {
                console.warn("WatchfaceStorePage: catalog parse error:", e)
            }
        }
        xhr.send()
    }

    function _addCommunityWatchfaces(catalog) {
        var skipList = { "tests": true, "fake-components": true }
        for (var j = 0; j < catalog.length; j++) {
            var entry = catalog[j]
            if (entry.type !== "dir") continue
            if (entry.name[0] === ".") continue
            if (skipList[entry.name]) continue
            var isInstalled = FileInfo.exists(WatchfaceHelper.userWatchfacePath() + entry.name + ".qml")
            storeModel.append({ name: entry.name, isInstalled: isInstalled })
        }
    }

    function _ensurePreview(name) {
        if (_pendingPreviews[name]) return
        var cacheDest = _cacheBase + previewSize + "/" + name + ".png"
        if (FileInfo.exists(cacheDest)) return
        _pendingPreviews[name] = true
        WatchfaceHelper.mkpath(_cacheBase + previewSize)
        WatchfaceHelper.downloadFile(
            _rawBase + name + "/usr/share/asteroid-launcher/watchfaces-preview/" + previewSize + "/" + name + ".png",
            cacheDest)
    }

    function _startDownload(name) {
        if (downloadingName !== "") return
        downloadingName = name
        installingName = name
        _pendingFiles = 0
        _inFlightXhrs = 0

        var userBase = WatchfaceHelper.userWatchfacePath()
        var userRoot = userBase.substring(0, userBase.lastIndexOf("watchfaces/"))

        _queueDownload(
            _rawBase + name + "/usr/share/asteroid-launcher/watchfaces/" + name + ".qml",
            userBase + name + ".qml")
        _queueDownload(
            _rawBase + name + "/usr/share/asteroid-launcher/watchfaces-preview/" + previewSize + "/" + name + ".png",
            userRoot + "watchfaces-preview/" + previewSize + "/" + name + ".png")
        _fetchDirectory(
            _apiBase + name + "/usr/share/asteroid-launcher/watchfaces-img/",
            userRoot + "watchfaces-img/",
            false)
        _fetchDirectory(
            _apiBase + name + "/usr/share/fonts/",
            WatchfaceHelper.userFontsPath(),
            true)
    }

    function _queueDownload(url, dest) {
        _pendingFiles++
        WatchfaceHelper.mkpath(dest.substring(0, dest.lastIndexOf("/")))
        WatchfaceHelper.downloadFile(url, dest)
    }

    function _fetchDirectory(apiUrl, destPrefix, isFont) {
        _inFlightXhrs++
        var xhr = new XMLHttpRequest()
        xhr.open("GET", apiUrl)
        xhr.timeout = 10000
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            _inFlightXhrs--
            if (xhr.status === 200) {
                try {
                    var files = JSON.parse(xhr.responseText)
                    for (var i = 0; i < files.length; i++) {
                        if (files[i].type === "file")
                            _queueDownload(files[i].download_url, destPrefix + files[i].name)
                    }
                } catch(e) {
                    console.warn("WatchfaceStorePage: directory parse error:", e)
                }
            }
            _checkInstallComplete()
        }
        xhr.send()
    }

    function _checkInstallComplete() {
        if (_pendingFiles !== 0 || _inFlightXhrs !== 0) return
        if (downloadingName === "") return

        var name = downloadingName
        downloadingName = ""

        if (storePage.failedName !== name) {
            for (var i = 0; i < storeModel.count; i++) {
                if (storeModel.get(i).name === name) {
                    storeModel.setProperty(i, "isInstalled", true)
                    break
                }
            }
            activeWatchface.value = WatchfaceHelper.userAssetPath() + "watchfaces/" + name + ".qml"
            restartPending = true
        }
        installingName = ""
    }
}
