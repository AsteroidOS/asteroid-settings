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

import QtQml.Models
import QtQuick
import QtQuick.Effects
import org.asteroid.controls
import org.asteroid.settings
import org.asteroid.utils

Item {
    id: watchfaceSelector

    // The nightstand page embeds this selector for face selection only; it
    // sets storeEnabled false, which drops the catalog footer and the network
    // probe so no store surface leaks into that path.
    property bool storeEnabled: true
    // Context for faces instantiated inside the settings app (the previewless
    // tile fallback and the on-demand settings host): faces read these
    // unqualified from the launcher scope.
    property bool displayAmbient: false
    property bool nightstand: false
    // The app-wide store backend. A singleton: however many pages embed the
    // selector, there is one set of watchers and one model.
    readonly property var storeModel: WatchfaceStoreModel
    // The size a tile draws its preview at, handed to the model so it picks the
    // closest preview folder instead of the first one on disk. Same proportion
    // the launcher grabs at, so its render lands on the tile unscaled.
    readonly property int previewSize: Math.round(Dims.l(40))
    // Selection feedback is split in two: the wallpaper backdrop follows the
    // tapped face instantly (selectedPath), while the name pill waits for the
    // face to finish loading (tile.isActive). Defaults to the live active face;
    // a tap or an install auto-activation reassigns it immediately.
    property string selectedPath: watchface
    readonly property string activeBaseName: {
        var v = watchface;
        var lastSlash = v.lastIndexOf("/");
        var name = lastSlash >= 0 ? v.substring(lastSlash + 1) : v;
        var dotQml = name.indexOf(".qml");
        return dotQml >= 0 ? name.substring(0, dotQml) : name;
    }
    // The name as shown, without the ordering prefix. Stock faces are filed
    // 000- to 017- so the directory keeps them in curated rather than
    // alphabetical order; the digits are a filing device, not part of the
    // name. Display only — every lookup keyed by name (settings detection,
    // install, activation, preview paths) keeps the real on-disk name.
    readonly property string activeDisplayName: activeBaseName.replace(/^\d{3}-/, "")
    // From a cached source scan, not from an instantiated face: the live tile
    // render is only a fallback for faces lacking a preview image, so an item
    // to ask is usually not around.
    readonly property bool activeHasSettings: storeModel.faceHasSettings(activeBaseName)
    // Armed by a gate-opening "get more" tap; the model reset that actually
    // brings the catalog rows repositions the view onto the first of them.
    // With an empty cache those rows only arrive with the network response,
    // one or two resets later, so the anchor waits on the reset, not the tap.
    property int pendingBrowseAnchor: -1

    // Reflect the online state on open; the catalog is only fetched when the
    // user taps "get more"/"update", never automatically.
    Component.onCompleted: {
        if (storeEnabled)
            storeModel.probe();

    }

    Binding {
        target: storeModel
        property: "activeWatchface"
        value: watchface
    }

    Binding {
        target: storeModel
        property: "previewSize"
        value: previewSize
    }

    Connections {
        // A completed install activates the face only if it is still the user's
        // current selection. selectedPath is set the moment an install begins, so
        // tapping another face mid-download moves the intent and a slow install
        // never steals activation from the newer choice.
        function onActivated(value) {
            if (watchfaceSelector.selectedPath === value)
                watchface = value;

        }

        // Set-once wallpaper: the engine emits this only on a fresh install (never
        // on re-activation), so the bundled wallpaper is forced once for the peek
        // preview and the user's later wallpaper choice is respected afterwards.
        function onWallpaperForced(url) {
            wallpaperSource.value = url;
        }

        // Any reset, whatever its trigger (catalog refresh, connectivity
        // flip, a face pushed or removed on disk), keeps the user's place:
        // remember the position just before, restore just after. Cells are
        // uniform so the restored offset is exact. The get-more anchor takes
        // precedence when armed.
        function onModelAboutToBeReset() {
            grid.savedContentY = grid.contentY;
        }

        // The fetch settled without producing catalog rows (offline race,
        // empty catalog): disarm so a later unrelated reset cannot jump.
        function onLoadingChanged() {
            if (!storeModel.loading && grid.count <= watchfaceSelector.pendingBrowseAnchor)
                watchfaceSelector.pendingBrowseAnchor = -1;

        }

        target: storeModel
    }


    // Context the live-rendered fallback faces expect (a face without any
    // preview image renders itself in the tile). Page scope, so every
    // delegate of the grid below resolves them.
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

    Component {
        id: tileDelegate

        Item {
            id: tile

            property bool _pressActive: false
            property bool _scrollCancelled: false
            property bool _downloadFiredOnHold: false
            readonly property bool isActive: model.active
            readonly property bool isInstalled: model.installed
            readonly property bool isUser: model.installed && !model.stock
            readonly property string baseName: model.name
            readonly property bool isInstalling: model.downloading
            readonly property bool isFailed: model.failed
            readonly property string missingModule: model.missingModule
            readonly property string resolvedFilePath: storeModel.watchfaceUrl(model.name)

            width: GridView.view.cellWidth
            height: GridView.view.cellHeight
            onIsInstallingChanged: {
                if (!isInstalling && isInstalled)
                    bumpAnim.start();

            }
            onIsFailedChanged: {
                if (isFailed)
                    failAnim.start();

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

            Timer {
                id: contextHoldTimer

                interval: 800
                repeat: false
                onTriggered: {
                    if (!tile.isInstalled) {
                        if (!tile.isInstalling) {
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
                            // Record the intent so the install activates on completion
                            // only if this is still the selected face.
                            watchfaceSelector.selectedPath = resolvedFilePath;
                            storeModel.install(tile.baseName);
                        }
                        return ;
                    }
                    pressOverlayIn.stop();
                    pressOverlay.opacity = 0;
                    // Detection comes from the cached source scan, never from
                    // the tile's live render (which only exists for faces
                    // lacking a preview image). The container instantiates the
                    // face on demand to reach its settingsPage; a user face
                    // opens it even without settings, as the remove target.
                    if (tile.isUser || storeModel.faceHasSettings(tile.baseName))
                        layerStack.push(watchfaceSettingsContainerComponent, {
                        "watchfaceName": tile.baseName,
                        "watchfaceFile": resolvedFilePath,
                        "isStock": !tile.isUser,
                        "store": storeModel
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

                    property bool previewExists: model.preview !== ""

                    z: 1
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    opacity: tile.isInstalled ? 1 : 0.7
                    source: previewExists ? "file://" + model.preview : ""
                    asynchronous: true
                    cache: false
                    fillMode: Image.PreserveAspectFit
                    // Every face without a device preview shows a static substitute
                    // — the repo gallery thumbnail — so browsing never live-loads a
                    // watchface. The device-specific grab replaces it on activation.
                    Component.onCompleted: {
                        if (!previewExists)
                            storeModel.requestPreview(model.name);

                    }

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
                    // Last-resort display only. A face with no preview anywhere —
                    // no launcher grab, no stock image, no gallery thumbnail —
                    // renders live so its tile is not empty. The launcher captures
                    // a real preview once the face is activated; this is just the
                    // fallback for bare QML a user pushed while learning. Faces
                    // that HAVE any preview never render here, and nothing is
                    // grabbed in the settings process.
                    visible: !previewPng.previewExists && tile.isInstalled
                    active: !previewPng.previewExists && tile.isInstalled
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    source: (!previewPng.previewExists && tile.isInstalled) ? resolvedFilePath : ""
                    asynchronous: true
                }

                Image {
                    id: wallpaperBack

                    // The wallpaper as a displayable image: a live wallpaper is
                    // a .qml whose still sibling is the .jpg next to it, so the
                    // backdrop never asks the Image to decode QML. Prefer the
                    // pre-scaled copy for this tile size, fall back to full.
                    property string previewSizePath: "wallpapers/" + Dims.w(50)
                    property string wallpaperImg: wallpaperSource.value.replace(/\.[^.]+$/, ".jpg")
                    property string wallpaperPreviewImg: wallpaperImg.replace("wallpapers/full", previewSizePath)

                    z: 0
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    visible: opacity > 0
                    // Instant selection feedback, decoupled from the load-gated
                    // isActive: the backdrop follows the tapped face immediately.
                    opacity: resolvedFilePath === watchfaceSelector.selectedPath ? 1 : 0
                    source: opacity > 0 ? (FileInfo.exists(wallpaperPreviewImg.slice(7)) ? wallpaperPreviewImg : wallpaperImg) : ""

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

                // Greyed overlay for a face whose imports are not met on this
                // device: darken it and name the missing module so the user knows
                // why it is unavailable instead of being offered a blank face.
                Rectangle {
                    z: 50
                    anchors.fill: parent
                    visible: tile.missingModule !== ""
                    // Dim via the colour's alpha, not the item's opacity, so the
                    // reason text below stays crisp instead of being dimmed with it.
                    color: "#8c000000"

                    Text {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        color: "#ff5252"
                        text: "needs\n" + tile.missingModule.split(".").pop()

                        // Condensed to keep the module name on one line; sized up
                        // now that the narrow family leaves the width to spare.
                        font {
                            pixelSize: parent.height * 0.195
                            family: "Noto Sans Condensed"
                        }

                    }

                }

                MouseArea {
                    property real startX: 0
                    property real startY: 0

                    anchors.fill: parent
                    onPressed: (mouse) => {
                        startX = mouse.x;
                        startY = mouse.y;
                        _scrollCancelled = false;
                        _pressActive = true;
                        bumpAnim.stop();
                        failAnim.stop();
                        opacityAnim.stop();
                        colorAnim.stop();
                        if (!tile.isInstalled && !tile.isInstalling) {
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
                        } else if (tile.isInstalled && tile.missingModule === "") {
                            pressOverlayIn.stop();
                            pressOverlayOut.stop();
                            pressOverlay.opacity = 0;
                            pressOverlayIn.start();
                            contextHoldTimer.restart();
                        }
                    }
                    onPositionChanged: (mouse) => {
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
                        if (!tile.isInstalled && !tile.isInstalling) {
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
                            // Record the intent now so the install activates on
                            // completion only if this is still the selected face.
                            watchfaceSelector.selectedPath = resolvedFilePath;
                            storeModel.install(tile.baseName);
                        } else if (tile.isInstalled && tile.missingModule === "") {
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
                            // Instant selection: record the intent (which moves the
                            // wallpaper backdrop) and activate at once; the name pill
                            // follows when the face finishes loading.
                            watchfaceSelector.selectedPath = resolvedFilePath;
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

                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: maskShape
                }

            }

            // External mask shape for the MultiEffect. Kept out of maskArea so
            // it is not part of the layered content, only its alpha is sampled.
            // Geometry matches the mask source exactly.
            Rectangle {
                id: maskShape

                anchors.centerIn: maskArea
                width: Math.min(wallpaperBack.width, wallpaperBack.height)
                height: width
                radius: maskArea.radius
                visible: false
                layer.enabled: true
            }

            Rectangle {
                id: namePill

                width: parent.width
                height: Dims.l(11)
                radius: height / 2
                color: "#cc000000"
                visible: opacity > 0
                opacity: tile.isActive ? 1 : 0

                anchors {
                    verticalCenter: parent.bottom
                    verticalCenterOffset: -Dims.l(3)
                    horizontalCenter: parent.horizontalCenter
                }

                Row {
                    id: pillContent

                    anchors.centerIn: parent
                    spacing: Dims.l(1)
                    height: parent.height

                    Marquee {
                        id: pillMarquee

                        width: namePill.width - Dims.l(6) - (pillGear.visible ? pillGear.width + Dims.l(1) : 0)
                        text: watchfaceSelector.activeDisplayName
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

    GridView {
        id: grid

        property real savedContentY: -1

        anchors.fill: parent
        cellWidth: Dims.w(50)
        cellHeight: Dims.h(45)
        clip: true
        // One virtualized grid over the whole model: stock rows first, then the
        // community section, in the order the model provides. The grid owns the
        // scrolling so delegates are created on demand — sizing grids to their
        // full content inside an outer Flickable instantiated every tile at
        // once, which was most of the store's old multi-second page open.
        model: storeModel
        delegate: tileDelegate
        // The armed "get more" anchor lands here, not on the model signal: the
        // view's count only reflects the new rows once IT has processed the
        // reset, which is after the model's own subscribers ran.
        onCountChanged: {
            var anchor = watchfaceSelector.pendingBrowseAnchor;
            if (anchor >= 0 && count > anchor) {
                watchfaceSelector.pendingBrowseAnchor = -1;
                grid.savedContentY = -1;
                Qt.callLater(function() {
                    grid.positionViewAtIndex(anchor, GridView.Beginning);
                });
            } else if (grid.savedContentY >= 0) {
                var y = grid.savedContentY;
                grid.savedContentY = -1;
                Qt.callLater(function() {
                    grid.contentY = Math.max(0, Math.min(y, grid.contentHeight - grid.height));
                });
            }
        }

        // The store actions ride along as the grid footer.
        footer: Column {
            width: grid.width

            Item {
                width: parent.width
                height: Dims.l(4)
            }

            RowSeparator {
                visible: watchfaceSelector.storeEnabled
            }

            Item {
                visible: watchfaceSelector.storeEnabled
                width: parent.width
                height: visible ? Dims.h(32) : 0
                opacity: storeModel.online ? 1 : 0.45

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
                        readonly property string loadingText: qsTrId("id-loading")
                        //% "Update"
                        readonly property string updateText: qsTrId("id-update")
                        //% "Get more"
                        readonly property string getMoreText: qsTrId("id-get-more")

                        width: Dims.l(70)
                        horizontalAlignment: Text.AlignHCenter
                        text: storeModel.loading ? loadingText : storeModel.hasCatalog ? updateText : getMoreText
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
                        // Dimmed AND inert offline: a catalog fetch cannot
                        // succeed, and the gated rows could not install anyway.
                        if (storeModel.loading || !storeModel.online)
                            return ;

                        // Arm the scroll anchor before the rebuilds: the view
                        // should land on the first catalog row — the content
                        // this tap asked for — not jump back to the top. The
                        // pre-tap row count is exactly that row's index.
                        // Update taps (browse already open) keep their place.
                        if (!storeModel.browseActive)
                            watchfaceSelector.pendingBrowseAnchor = grid.count;

                        storeModel.refresh();
                    }
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

}
