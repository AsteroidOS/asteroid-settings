/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
 *               2023 - Arseniy Movshev <dodoradio@outlook.com>
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

import Nemo.Configuration 1.0
import Nemo.Time 1.0
import Qt.labs.folderlistmodel 2.1
import QtGraphicalEffects 1.12
import QtQuick 2.9
import org.asteroid.controls 1.0
import org.asteroid.settings 1.0
import org.asteroid.utils 1.0

Item {

    id: watchfaceSelector

    property bool storeAvailable: false
    property bool loadingCatalog: false
    property bool catalogCacheExists: false
    property bool restartPending: false
    property string installingName: ""
    property string downloadingName: ""
    property string failedName: ""
    property int _previewsDone: 0
    property int _previewsTotal: 0
    property var _catalog: []
    property var _pendingPreviews: ({
    })
    property int _pendingFiles: 0
    property int _inFlightXhrs: 0
    property bool _skipNextRebuild: false
    property bool activeHasSettings: false
    readonly property string activeBaseName: {
        var v = activeWatchface.value;
        var lastSlash = v.lastIndexOf("/");
        var name = lastSlash >= 0 ? v.substring(lastSlash + 1) : v;
        var dotQml = name.indexOf(".qml");
        return dotQml >= 0 ? name.substring(0, dotQml) : name;
    }
    readonly property string _cacheBase: WatchfaceHelper.cachePath()
    readonly property string _catalogCache: WatchfaceHelper.cachePath() + "catalog.json"
    readonly property string _apiBase: "https://api.github.com/repos/AsteroidOS/unofficial-watchfaces/contents/"
    readonly property string _rawBase: "https://raw.githubusercontent.com/AsteroidOS/unofficial-watchfaces/master/"
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
    property int _communityBatchSize: 8
    property int _communityBatchIndex: 0

    function _rebuildCommunity() {
        if (_skipNextRebuild) {
            _skipNextRebuild = false;
            return ;
        }
        communityModel.clear();
        communityBatchTimer.stop();
        _communityBatchIndex = 0;
        if (catalogCacheExists && _catalog.length > 0) {
            _appendCommunityBatch();
        } else {
            for (var j = 0; j < userFolderModel.count; j++) {
                var fn = userFolderModel.get(j, "fileName");
                var bn = fn.slice(0, -4);
                communityModel.append({
                    "name": bn,
                    "fileName": fn,
                    "filePath": "file://" + WatchfaceHelper.userWatchfacePath() + fn,
                    "isInstalled": true
                });
            }
        }
    }

    function _appendCommunityBatch() {
        var end = Math.min(_communityBatchIndex + _communityBatchSize, _catalog.length);
        for (var i = _communityBatchIndex; i < end; i++) {
            var name = _catalog[i];
            var installed = FileInfo.exists(WatchfaceHelper.userWatchfacePath() + name + ".qml");
            communityModel.append({
                "name": name,
                "fileName": name + ".qml",
                "filePath": "file://" + WatchfaceHelper.userWatchfacePath() + name + ".qml",
                "isInstalled": installed
            });
        }
        _communityBatchIndex = end;
        if (_communityBatchIndex < _catalog.length)
            communityBatchTimer.restart();

    }

    function probeConnection() {
        var xhr = new XMLHttpRequest();
        xhr.open("HEAD", "https://api.github.com");
        xhr.timeout = 6000;
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return ;

            watchfaceSelector.storeAvailable = (xhr.status > 0 && xhr.status < 500);
        };
        xhr.send();
    }

    function _loadCachedCatalog() {
        var raw = WatchfaceHelper.readFile(_catalogCache);
        if (!raw) {
            catalogCacheExists = false;
            rebuildCommunityTimer.restart();
            return ;
        }
        try {
            var parsed = JSON.parse(raw);
            if (Array.isArray(parsed) && (parsed.length === 0 || typeof parsed[0] === "string")) {
                _catalog = parsed;
            } else {
                _catalog = [];
                catalogCacheExists = false;
            }
        } catch (e) {
            _catalog = [];
            catalogCacheExists = false;
        }
        rebuildCommunityTimer.restart();
    }

    function _fetchCatalog() {
        if (loadingCatalog)
            return ;

        loadingCatalog = true;
        var xhr = new XMLHttpRequest();
        xhr.open("GET", _apiBase);
        xhr.timeout = 10000;
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return ;

            if (xhr.status < 200 || xhr.status >= 300) {
                loadingCatalog = false;
                return ;
            }
            try {
                var parsed = JSON.parse(xhr.responseText);
                var skipList = {
                    "tests": true,
                    "fake-components": true
                };
                var names = [];
                for (var i = 0; i < parsed.length; i++) {
                    var entry = parsed[i];
                    if (entry.type !== "dir")
                        continue;

                    if (entry.name[0] === ".")
                        continue;

                    if (skipList[entry.name])
                        continue;

                    names.push(entry.name);
                }
                _catalog = names;
                WatchfaceHelper.writeFile(_catalogCache, JSON.stringify(names));
                catalogCacheExists = true;
                rebuildCommunityTimer.restart();
                _refreshAllPreviews();
            } catch (e) {
                loadingCatalog = false;
            }
        };
        xhr.send();
    }

    function _refreshAllPreviews() {
        _previewsDone = 0;
        _previewsTotal = 0;
        for (var i = 0; i < _catalog.length; i++) {
            var name = _catalog[i];
            var dest = _cacheBase + previewSize + "/" + name + ".png";
            if (FileInfo.exists(dest))
                continue;

            _previewsTotal++;
            _ensurePreview(name);
        }
        if (_previewsTotal === 0)
            loadingCatalog = false;

    }

    function _ensurePreview(name) {
        if (_pendingPreviews[name])
            return ;

        var cacheDest = _cacheBase + previewSize + "/" + name + ".png";
        if (FileInfo.exists(cacheDest))
            return ;

        _pendingPreviews[name] = true;
        WatchfaceHelper.mkpath(_cacheBase + previewSize);
        WatchfaceHelper.downloadFile(_rawBase + name + "/usr/share/asteroid-launcher/watchfaces-preview/" + previewSize + "/" + name + ".png", cacheDest);
    }

    function _startDownload(name) {
        if (downloadingName !== "")
            return ;

        downloadingName = name;
        installingName = name;
        _pendingFiles = 0;
        _inFlightXhrs = 0;
        var userBase = WatchfaceHelper.userWatchfacePath();
        var userRoot = userBase.substring(0, userBase.lastIndexOf("watchfaces/"));
        _queueDownload(_rawBase + name + "/usr/share/asteroid-launcher/watchfaces/" + name + ".qml", userBase + name + ".qml");
        _queueDownload(_rawBase + name + "/usr/share/asteroid-launcher/watchfaces-preview/" + previewSize + "/" + name + ".png", userRoot + "watchfaces-preview/" + previewSize + "/" + name + ".png");
        _fetchDirectory(_apiBase + name + "/usr/share/asteroid-launcher/watchfaces-img/", userRoot + "watchfaces-img/");
        _fetchDirectory(_apiBase + name + "/usr/share/asteroid-launcher/wallpapers/full/", userRoot + "wallpapers/full/");
        _fetchDirectory(_apiBase + name + "/usr/share/fonts/", WatchfaceHelper.userFontsPath());
    }

    function _queueDownload(url, dest) {
        _pendingFiles++;
        WatchfaceHelper.mkpath(dest.substring(0, dest.lastIndexOf("/")));
        WatchfaceHelper.downloadFile(url, dest);
    }

    function _fetchDirectory(apiUrl, destPrefix) {
        _inFlightXhrs++;
        var xhr = new XMLHttpRequest();
        xhr.open("GET", apiUrl);
        xhr.timeout = 10000;
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return ;

            _inFlightXhrs--;
            if (xhr.status === 200) {
                try {
                    var files = JSON.parse(xhr.responseText);
                    for (var i = 0; i < files.length; i++) {
                        if (files[i].type === "file")
                            _queueDownload(files[i].download_url, destPrefix + files[i].name);
                    }
                } catch (e) {
                    console.warn("WatchfaceSelector: directory parse error:", e);
                }
            }
            _checkInstallComplete();
        };
        xhr.send();
    }

    function _checkInstallComplete() {
        if (_pendingFiles !== 0 || _inFlightXhrs !== 0)
            return ;

        if (downloadingName === "")
            return ;

        var name = downloadingName;
        downloadingName = "";
        if (failedName !== name) {
            _skipNextRebuild = true;
            for (var i = 0; i < communityModel.count; i++) {
                if (communityModel.get(i).name === name) {
                    communityModel.setProperty(i, "isInstalled", true);
                    break;
                }
            }
            activationDelayTimer.pendingPath = WatchfaceHelper.userAssetPath() + "watchfaces/" + name + ".qml";
            activationDelayTimer.restart();
            restartPending = true;
        }
        installingName = "";
    }

    Component.onCompleted: {
        catalogCacheExists = FileInfo.exists(_catalogCache);
        if (catalogCacheExists)
            _loadCachedCatalog();
        else
            rebuildCommunityTimer.restart();
        probeConnection();
    }

    ConfigurationValue {
        id: activeWatchface

        key: "/desktop/asteroid/watchface"
        defaultValue: "file:///usr/share/asteroid-launcher/watchfaces/000-default-digital.qml"
    }

    FolderListModel {
        id: stockModel

        folder: assetPath + "watchfaces"
        nameFilters: ["*.qml"]
        showDirs: false
    }

    FolderListModel {
        id: userFolderModel

        folder: "file://" + WatchfaceHelper.userWatchfacePath()
        nameFilters: ["*.qml"]
        showDirs: false
        onCountChanged: {
            if (watchfaceSelector.downloadingName === "")
                rebuildCommunityTimer.restart();

        }
    }

    ListModel {
        id: communityModel
    }

    Timer {
        id: rebuildCommunityTimer

        interval: 0
        repeat: false
        onTriggered: _rebuildCommunity()
    }

    Timer {
        id: communityBatchTimer

        interval: 50
        repeat: false
        onTriggered: _appendCommunityBatch()
    }

    Connections {
        function onWatchfaceRemoved(name) {
            watchfaceSelector._skipNextRebuild = true;
            for (var i = 0; i < communityModel.count; i++) {
                if (communityModel.get(i).name === name) {
                    if (catalogCacheExists)
                        communityModel.setProperty(i, "isInstalled", false);
                    else
                        communityModel.remove(i);
                    break;
                }
            }
        }

        function onDownloadComplete(destPath, success) {
            // Preview cache download
            if (destPath.indexOf(watchfaceSelector._cacheBase) === 0 && destPath.indexOf(".png") > 0) {
                var pname = destPath.substring(destPath.lastIndexOf("/") + 1).replace(".png", "");
                delete watchfaceSelector._pendingPreviews[pname];
                watchfaceSelector._previewsDone++;
                if (!success) {
                    var idx = watchfaceSelector._catalog.indexOf(pname);
                    if (idx >= 0) {
                        watchfaceSelector._catalog.splice(idx, 1);
                        WatchfaceHelper.writeFile(watchfaceSelector._catalogCache, JSON.stringify(watchfaceSelector._catalog));
                    }
                    rebuildCommunityTimer.restart();
                }
                var pendingCount = 0;
                for (var k in watchfaceSelector._pendingPreviews) pendingCount++
                if (pendingCount === 0) {
                    watchfaceSelector.loadingCatalog = false;
                    rebuildCommunityTimer.restart();
                }
                return ;
            }
            // Install download (QML, preview, assets, fonts)
            if (watchfaceSelector.downloadingName !== "") {
                if (!success && destPath.indexOf(".qml") === destPath.length - 4)
                    watchfaceSelector.failedName = watchfaceSelector.downloadingName;

                watchfaceSelector._pendingFiles--;
                watchfaceSelector._checkInstallComplete();
            }
        }

        target: WatchfaceHelper
    }

    Timer {
        id: activationDelayTimer

        property string pendingPath: ""

        interval: 400
        repeat: false
        onTriggered: {
            if (pendingPath !== "") {
                activeWatchface.value = pendingPath
                pendingPath = ""
            }
        }
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
        onTriggered: WatchfaceHelper.restartSession()
    }

    Component {
        id: tileDelegate

        Item {
            id: tile

            property bool _pressActive: false
            property bool _scrollCancelled: false
            property bool _downloadFiredOnHold: false
            readonly property bool isActive: watchface === resolvedFilePath
            readonly property bool isInstalled: typeof model.isInstalled === "undefined" ? true : model.isInstalled
            readonly property bool isUser: GridView.view.sectionIsUser
            readonly property string baseName: model.fileName ? model.fileName.slice(0, -4) : (model.name || "")
            readonly property bool isInstalling: watchfaceSelector.installingName === baseName
            readonly property string resolvedFilePath: tile.isUser ? model.filePath : assetPath + "watchfaces/" + model.fileName

            width: GridView.view.cellWidth
            height: GridView.view.cellHeight
            onIsInstallingChanged: {
                if (!isInstalling && isInstalled)
                    bumpAnim.start()
            }
            
            onIsActiveChanged: {
                if (isActive && previewQml.item)
                    watchfaceSelector.activeHasSettings = typeof previewQml.item.settingsPage !== "undefined"
            }

            Connections {
                target: previewQml

                function onStatusChanged() {
                    if (previewQml.status === Loader.Ready && tile.isActive)
                        watchfaceSelector.activeHasSettings = previewQml.item && typeof previewQml.item.settingsPage !== "undefined"
                }
            }

            Rectangle {
                id: stateBg

                width: Dims.l(40)
                height: width
                radius: DeviceSpecs.hasRoundScreen ? width : Dims.l(3)
                anchors.centerIn: parent
                color: !isInstalled ? "#000000" : "transparent"
                opacity: !isInstalled ? 0.2 : (isActive ? 0.2 : 0)

                NumberAnimation {
                    id: opacityAnim

                    target: stateBg
                    property: "opacity"
                    easing.type: Easing.OutQuad
                }

                ColorAnimation {
                    id: colorAnim

                    target: stateBg
                    property: "color"
                    easing.type: Easing.OutQuad
                }

                SequentialAnimation {
                    id: bumpAnim

                    PropertyAction {
                        target: stateBg
                        property: "color"
                        value: "#44ff88"
                    }

                    NumberAnimation {
                        target: stateBg
                        property: "opacity"
                        to: 1
                        duration: 200
                        easing.type: Easing.OutQuad
                    }

                    NumberAnimation {
                        target: stateBg
                        property: "opacity"
                        to: 0
                        duration: 200
                        easing.type: Easing.InQuad
                    }
                    
                }

                SequentialAnimation {
                    id: failAnim

                    onStopped: watchfaceSelector.failedName = ""

                    ColorAnimation {
                        target: stateBg
                        property: "color"
                        to: "#ff4444"
                        duration: 200
                    }

                    PauseAnimation {
                        duration: 1200
                    }

                    ColorAnimation {
                        target: stateBg
                        property: "color"
                        to: "#000000"
                        duration: 400
                    }

                    NumberAnimation {
                        target: stateBg
                        property: "opacity"
                        to: 0.2
                        duration: 300
                    }

                }

            }

            Connections {
                function onFailedNameChanged() {
                    if (watchfaceSelector.failedName === tile.baseName)
                        failAnim.start();

                }

                target: watchfaceSelector
            }

            Timer {
                id: contextHoldTimer

                interval: 800
                repeat: false
                onTriggered: {
                    if (!tile.isInstalled) {
                        if (watchfaceSelector.downloadingName === "") {
                            _downloadFiredOnHold = true;
                            colorAnim.stop();
                            opacityAnim.stop();
                            colorAnim.from = stateBg.color;
                            colorAnim.to = "#44ff88";
                            colorAnim.duration = 300;
                            colorAnim.start();
                            opacityAnim.from = stateBg.opacity;
                            opacityAnim.to = 0.5;
                            opacityAnim.duration = 300;
                            opacityAnim.easing.type = Easing.OutQuad;
                            opacityAnim.start();
                            watchfaceSelector._startDownload(tile.baseName);
                        }
                        return ;
                    }
                    pressOverlayIn.stop();
                    pressOverlay.opacity = 0;
                    var hasSettings = previewQml.item && typeof previewQml.item.settingsPage !== "undefined";
                    if (hasSettings && tile.isUser)
                        layerStack.push(watchfaceSettingsContainerComponent, {
                            "settingsPage": previewQml.item.settingsPage,
                            "watchfaceName": tile.baseName,
                            "watchfaceFile": resolvedFilePath
                        });
                    else if (hasSettings)
                        layerStack.push(previewQml.item.settingsPage);
                    else if (tile.isUser)
                        layerStack.push(watchfaceRemoveComponent, {
                            "watchfaceName": tile.baseName,
                            "watchfaceFile": resolvedFilePath
                        });
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
                layer.enabled: true

                Image {
                    id: previewPng

                    readonly property string sysPreviewImg: assetPath + "watchfaces-preview/" + watchfaceSelector.previewSize + "/" + tile.baseName + ".png"
                    readonly property string userPreviewImg: WatchfaceHelper.userAssetPath() + "watchfaces-preview/" + watchfaceSelector.previewSize + "/" + tile.baseName + ".png"
                    readonly property string cachePreviewImg: "file://" + watchfaceSelector._cacheBase + watchfaceSelector.previewSize + "/" + tile.baseName + ".png"
                    readonly property string previewImg: FileInfo.exists(sysPreviewImg) ? sysPreviewImg : FileInfo.exists(userPreviewImg) ? userPreviewImg : cachePreviewImg
                    property bool previewExists: FileInfo.exists(sysPreviewImg) || FileInfo.exists(userPreviewImg) || FileInfo.exists(cachePreviewImg)

                    z: 1
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    opacity: tile.isInstalled ? 1 : 0.7
                    source: previewExists ? previewImg : ""
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    mipmap: true

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.InOutQuad
                        }

                    }

                }

                Loader {
                    id: previewQml

                    z: 2
                    visible: !previewPng.previewExists && tile.isInstalled
                    active: visible || tile.isActive
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    source: tile.isInstalled ? resolvedFilePath : ""
                    asynchronous: true
                }

                Image {
                    id: wallpaperBack

                    property string previewSizePath: "wallpapers/" + Dims.w(50)
                    property string wallpaperPreviewImg: wallpaperSource.value.replace("\\wallpapers/full\\", previewSizePath).slice(0, -3) + "jpg"

                    z: 0
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    visible: opacity > 0
                    opacity: tile.isActive ? 1 : 0
                    source: opacity > 0 ? FileInfo.exists(wallpaperPreviewImg) ? wallpaperPreviewImg : wallpaperSource.value : ""

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 100
                        }

                    }

                }

                Rectangle {
                    id: pressOverlay

                    z: 3
                    anchors.fill: parent
                    color: "#000000"
                    opacity: 0

                    NumberAnimation {
                        id: pressOverlayIn

                        target: pressOverlay
                        property: "opacity"
                        from: 0
                        to: 0.5
                        duration: 800
                        easing.type: Easing.Linear
                    }

                    NumberAnimation {
                        id: pressOverlayOut

                        target: pressOverlay
                        property: "opacity"
                        duration: 150
                        easing.type: Easing.OutQuad
                    }

                }

                MouseArea {
                    property real startX: 0
                    property real startY: 0

                    anchors.fill: parent
                    onPressed: {
                        startX = mouse.x;
                        startY = mouse.y;
                        _scrollCancelled = false;
                        _pressActive = true;
                        bumpAnim.stop();
                        failAnim.stop();
                        opacityAnim.stop();
                        colorAnim.stop();
                        if (!tile.isInstalled && watchfaceSelector.downloadingName === "") {
                            _downloadFiredOnHold = false;
                            colorAnim.from = stateBg.color;
                            colorAnim.to = "#44ff88";
                            colorAnim.duration = 300;
                            colorAnim.start();
                            opacityAnim.from = stateBg.opacity;
                            opacityAnim.to = 0.35;
                            opacityAnim.duration = 300;
                            opacityAnim.easing.type = Easing.OutQuad;
                            opacityAnim.start();
                            contextHoldTimer.restart();
                        } else if (tile.isInstalled) {
                            pressOverlayIn.stop();
                            pressOverlayOut.stop();
                            pressOverlay.opacity = 0;
                            pressOverlayIn.start();
                            contextHoldTimer.restart();
                        }
                    }
                    onPositionChanged: {
                        if (_scrollCancelled)
                            return ;

                        var dx = Math.abs(mouse.x - startX);
                        var dy = Math.abs(mouse.y - startY);
                        if (dx > Dims.l(2) || dy > Dims.l(2)) {
                            _scrollCancelled = true;
                            _pressActive = false;
                            contextHoldTimer.stop();
                            pressOverlayIn.stop();
                            pressOverlayOut.from = pressOverlay.opacity;
                            pressOverlayOut.to = 0;
                            pressOverlayOut.start();
                            opacityAnim.stop();
                            colorAnim.stop();
                            colorAnim.from = stateBg.color;
                            colorAnim.to = !tile.isInstalled ? "#000000" : "transparent";
                            colorAnim.duration = 150;
                            colorAnim.start();
                            opacityAnim.from = stateBg.opacity;
                            opacityAnim.to = !tile.isInstalled ? 0.2 : (tile.isActive ? 0.2 : 0);
                            opacityAnim.duration = 150;
                            opacityAnim.easing.type = Easing.OutQuad;
                            opacityAnim.start();
                            mouse.accepted = false;
                        }
                    }
                    onReleased: {
                        if (_scrollCancelled)
                            return ;

                        contextHoldTimer.stop();
                        _pressActive = false;
                        if (_downloadFiredOnHold) {
                            _downloadFiredOnHold = false;
                            return ;
                        }
                        if (!tile.isInstalled && watchfaceSelector.downloadingName === "") {
                            colorAnim.stop();
                            opacityAnim.stop();
                            colorAnim.from = stateBg.color;
                            colorAnim.to = "#44ff88";
                            colorAnim.duration = 300;
                            colorAnim.start();
                            opacityAnim.from = stateBg.opacity;
                            opacityAnim.to = 0.5;
                            opacityAnim.duration = 300;
                            opacityAnim.easing.type = Easing.OutQuad;
                            opacityAnim.start();
                            watchfaceSelector._startDownload(tile.baseName);
                        } else if (tile.isInstalled) {
                            pressOverlayIn.stop();
                            pressOverlayOut.from = pressOverlay.opacity;
                            pressOverlayOut.to = 0;
                            pressOverlayOut.start();
                            opacityAnim.stop();
                            opacityAnim.from = stateBg.opacity;
                            opacityAnim.to = tile.isActive ? 0.2 : 0;
                            opacityAnim.duration = 200;
                            opacityAnim.easing.type = Easing.OutQuad;
                            opacityAnim.start();
                            watchface = resolvedFilePath;
                        }
                    }
                    onCanceled: {
                        contextHoldTimer.stop();
                        _pressActive = false;
                        _downloadFiredOnHold = false;
                        pressOverlayIn.stop();
                        pressOverlayOut.from = pressOverlay.opacity;
                        pressOverlayOut.to = 0;
                        pressOverlayOut.start();
                        opacityAnim.stop();
                        colorAnim.stop();
                        colorAnim.from = stateBg.color;
                        colorAnim.to = !tile.isInstalled ? "#000000" : "transparent";
                        colorAnim.duration = 200;
                        colorAnim.start();
                        opacityAnim.from = stateBg.opacity;
                        opacityAnim.to = !tile.isInstalled ? 0.2 : (tile.isActive ? 0.2 : 0);
                        opacityAnim.duration = 200;
                        opacityAnim.easing.type = Easing.OutQuad;
                        opacityAnim.start();
                    }
                }

                layer.effect: OpacityMask {

                    maskSource: Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(wallpaperBack.width, wallpaperBack.height)
                        height: width
                        radius: maskArea.radius
                    }

                }

            }

            Rectangle {
                id: namePill

                anchors {
                    verticalCenter: parent.bottom
                    verticalCenterOffset: -Dims.l(3)
                    horizontalCenter: parent.horizontalCenter
                }
                width: parent.width
                height: Dims.l(11)
                radius: height / 2
                color: "#cc000000"
                visible: opacity > 0
                opacity: tile.isActive ? 1 : 0

                Row {
                    id: pillContent

                    anchors.centerIn: parent
                    spacing: Dims.l(1)
                    height: parent.height

                    Marquee {
                        id: pillMarquee

                        width: namePill.width - Dims.l(6) - (pillGear.visible ? pillGear.width + Dims.l(1) : 0)
                        text: watchfaceSelector.activeBaseName
                        speed: 0.5
                    }

                    Icon {
                        id: pillGear

                        name: "ios-settings-outline"
                        width: Dims.l(7)
                        height: width
                        visible: watchfaceSelector.activeHasSettings
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: 0.7
                    }
                }
            }

        }

    }

    Flickable {
        id: outerFlick

        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.height
        clip: true

        Column {
            // ── Footer

            id: contentColumn

            width: outerFlick.width

            GridView {
                id: stockGrid

                property bool sectionIsUser: false

                width: parent.width
                height: Math.ceil(stockModel.count / 2) * cellHeight
                cellWidth: Dims.w(50)
                cellHeight: Dims.h(45)
                interactive: false
                model: stockModel
                delegate: tileDelegate

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

            }

            GridView {
                id: communityGrid

                property bool sectionIsUser: true

                width: parent.width
                height: visible ? Math.ceil(communityModel.count / 2) * cellHeight : 0
                cellWidth: Dims.w(50)
                cellHeight: Dims.h(45)
                interactive: false
                visible: communityModel.count > 0
                model: communityModel
                delegate: tileDelegate
            }

            Item {
                width: parent.width
                height: Dims.l(4)
            }

            RowSeparator {
            }

            Item {
                width: parent.width
                height: Dims.h(32)
                opacity: watchfaceSelector.storeAvailable ? 1 : 0.45

                Column {
                    anchors.centerIn: parent

                    Icon {
                        name: "ios-cloud-download-outline"
                        width: Dims.l(12)
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        //% "Loading"
                        //% "Update"
                        //% "Get more"

                        width: Dims.l(70)
                        horizontalAlignment: Text.AlignHCenter
                        text: watchfaceSelector.loadingCatalog ? qsTrId("id-loading") + " (" + watchfaceSelector._previewsDone + "/" + watchfaceSelector._previewsTotal + ")" : watchfaceSelector.catalogCacheExists ? qsTrId("id-update") : qsTrId("id-get-more")
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
                        if (!watchfaceSelector.storeAvailable) {
                            watchfaceSelector.probeConnection();
                            return ;
                        }
                        if (watchfaceSelector.loadingCatalog)
                            return ;

                        watchfaceSelector._fetchCatalog();
                    }
                }

            }

            RowSeparator {
                visible: watchfaceSelector.restartPending
            }

            Item {
                visible: watchfaceSelector.restartPending
                width: parent.width
                height: visible ? Dims.h(32) : 0

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
                        anchors.horizontalCenter: parent.horizontalCenter

                        font {
                            pixelSize: Dims.l(8)
                            family: "Noto Sans"
                            styleName: "SemiCondensed SemiBold"
                        }

                    }

                }

                HighlightBar {
                    onClicked: restartRemorse.start()
                }

            }

            Item {
                width: parent.width
                height: DeviceSpecs.hasRoundScreen ? Dims.l(8) : 0
            }

        }

    }

    Component {
        id: watchfaceSettingsContainerComponent

        WatchfaceSettingsContainer {
        }

    }

    Component {
        id: watchfaceRemoveComponent

        WatchfaceRemovePage {
        }

    }

}
