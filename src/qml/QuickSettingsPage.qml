/*
 * Copyright (C) 2025 Timo Könnecke <github.com/eLtMosen>
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
import QtGraphicalEffects 1.15
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import Nemo.Configuration 1.0
import Nemo.Mce 1.0

Item {
    id: quickSettingsPage

    // Battery status components for the ValueMeter
    MceBatteryLevel { id: batteryChargePercentage }
    MceBatteryState { id: batteryChargeState }
    MceChargerType { id: mceChargerType }

    // ConfigurationValue for toggle arrays
    ConfigurationValue {
        id: fixedToggles
        key: "/desktop/asteroid/quicksettings/fixed"
        defaultValue: ["lockButton", "settingsButton"]
    }

    ConfigurationValue {
        id: sliderToggles
        key: "/desktop/asteroid/quicksettings/slider"
        defaultValue: ["brightnessToggle", "bluetoothToggle", "hapticsToggle", "wifiToggle", "soundToggle", "cinemaToggle", "aodToggle", "powerOffToggle", "rebootToggle", "musicButton", "flashlightButton"]
    }

    ConfigurationValue {
        id: toggleEnabled
        key: "/desktop/asteroid/quicksettings/enabled"
        defaultValue: {
            "lockButton": true,
            "settingsButton": true,
            "brightnessToggle": true,
            "bluetoothToggle": true,
            "hapticsToggle": true,
            "wifiToggle": true,
            "soundToggle": true,
            "cinemaToggle": true,
            "aodToggle": true,
            "powerOffToggle": true,
            "rebootToggle": true,
            "musicButton": false,
            "flashlightButton": false
        }
    }

    ConfigurationValue {
        id: options
        key: "/desktop/asteroid/quicksettings/options"
        defaultValue: {
            "batteryBottom": true,
            "batteryAnimation": true,
            "batteryColored": false,
            "particleDesign": "diamonds"
        }
    }

    // Available toggle options with translatable names and icons
    property var toggleOptions: [
        //% "Lock Button"
        { id: "lockButton", name: qsTrId("id-toggle-lock"), icon: "ios-unlock", available: true },
        //% "Settings"
        { id: "settingsButton", name: qsTrId("id-toggle-settings"), icon: "ios-settings", available: true },
        //% "Brightness"
        { id: "brightnessToggle", name: qsTrId("id-toggle-brightness"), icon: "ios-sunny", available: true },
        //% "Bluetooth"
        { id: "bluetoothToggle", name: qsTrId("id-toggle-bluetooth"), icon: "ios-bluetooth", available: true },
        //% "Vibration"
        { id: "hapticsToggle", name: qsTrId("id-toggle-haptics"), icon: "ios-watch-vibrating", available: true },
        //% "Wifi Toggle"
        { id: "wifiToggle", name: qsTrId("id-toggle-wifi"), icon: "ios-wifi-outline", available: DeviceSpecs.hasWlan },
        //% "Mute Sound"
        { id: "soundToggle", name: qsTrId("id-toggle-sound"), icon: "ios-sound-indicator-high", available: DeviceSpecs.hasSpeaker },
        //% "Cinema Mode"
        { id: "cinemaToggle", name: qsTrId("id-toggle-cinema"), icon: "ios-film-outline", available: true },
        //% "AoD Toggle"
        { id: "aodToggle", name: qsTrId("id-always-on-display"), icon: "ios-watch-aod-on", available: true },
        //% "Poweroff"
        { id: "powerOffToggle", name: qsTrId("id-toggle-power-off"), icon: "ios-power", available: true },
        //% "Reboot"
        { id: "rebootToggle", name: qsTrId("id-toggle-reboot"), icon: "ios-refresh", available: true },
        //% "Music"
        { id: "musicButton", name: qsTrId("id-toggle-music"), icon: "ios-musical-notes-outline", available: true },
        //% "Flashlight"
        { id: "flashlightButton", name: qsTrId("id-toggle-flashlight"), icon: "ios-bulb-outline", available: true }
    ]

    // Layout properties
    property real rowHeight: Dims.h(18)
    property int draggedItemIndex: -1
    property int targetIndex: -1
    property int fixedRowLength: 2
    property real dragYOffset: 0
    property string draggedToggleId: ""
    property var particleDesigns: ["diamonds", "bubbles", "logos", "flashes"]
    property var toggleCache: ({})

    // Utility function to safely access object properties
    function safeGet(obj, prop, defaultValue) {
        return obj && obj[prop] !== undefined ? obj[prop] : defaultValue;
    }

    // Find toggle by ID with caching for performance
    function findToggle(toggleId) {
        if (toggleCache[toggleId] !== undefined) {
            return toggleCache[toggleId];
        }

        for (var i = 0; i < toggleOptions.length; i++) {
            if (toggleOptions[i].id === toggleId) {
                toggleCache[toggleId] = toggleOptions[i];
                return toggleOptions[i];
            }
        }
        toggleCache[toggleId] = null;
        return null;
    }

    // Clear cache when toggleOptions changes
    onToggleOptionsChanged: {
        toggleCache = ({});
    }

    // Get toggle name for display
    function getToggleName(toggleId) {
        var toggle = findToggle(toggleId);
        return toggle ? toggle.name : "";
    }

    // Get toggle icon for display
    function getToggleIcon(toggleId) {
        var toggle = findToggle(toggleId);
        return toggle ? toggle.icon : "";
    }

    ListModel {
        id: slotModel
        Component.onCompleted: {
            refreshModel();
        }
    }

    // Sort toggles by availability and original order
    function sortToggles(toggleIds) {
        return toggleIds.sort(function(a, b) {
            var toggleA = findToggle(a);
            var toggleB = findToggle(b);

            if (toggleA && toggleB) {
                if (toggleA.available && !toggleB.available) return -1;
                if (!toggleA.available && toggleB.available) return 1;
                if (toggleA.available && toggleB.available) {
                    var indexA = toggleOptions.findIndex(function(t) { return t.id === a; });
                    var indexB = toggleOptions.findIndex(function(t) { return t.id === b; });
                    return indexA - indexB;
                }
                return a.localeCompare(b);
            }
            return 0;
        });
    }

    // Populate the model with fixed and slider toggles
    function refreshModel() {
        slotModel.clear();

        var fixedTogglesArray = fixedToggles.value;
        var sliderTogglesArray = sliderToggles.value;

        //% "Fixed Row"
        slotModel.append({ type: "label", labelText: qsTrId("id-fixed-row"), toggleId: "", listView: "" });
        for (var i = 0; i < fixedTogglesArray.length && i < fixedRowLength; i++) {
            var toggleId = fixedTogglesArray[i];
            if (toggleId) {
                var toggle = findToggle(toggleId);
                if (toggle && toggle.available) {
                    slotModel.append({
                        type: "toggle",
                        toggleId: toggleId,
                        listView: "fixed",
                        labelText: ""
                    });
                }
            }
        }
        for (i = 0; i < fixedTogglesArray.length && countFixedToggles() < fixedRowLength; i++) {
            toggleId = fixedTogglesArray[i];
            if (toggleId) {
                toggle = findToggle(toggleId);
                if (toggle && !toggle.available && !isToggleInFixedRow(toggleId)) {
                    slotModel.append({
                        type: "toggle",
                        toggleId: toggleId,
                        listView: "fixed",
                        labelText: ""
                    });
                }
            }
        }

        while (countFixedToggles() < fixedRowLength) {
            var foundAvailableToggle = false;
            for (var t = 0; t < toggleOptions.length; t++) {
                if (toggleOptions[t].available && !isToggleInFixedRow(toggleOptions[t].id)) {
                    slotModel.append({
                        type: "toggle",
                        toggleId: toggleOptions[t].id,
                        listView: "fixed",
                        labelText: ""
                    });
                    foundAvailableToggle = true;
                    break;
                }
            }
            if (!foundAvailableToggle) {
                for (t = 0; t < toggleOptions.length; t++) {
                    if (!isToggleInFixedRow(toggleOptions[t].id)) {
                        slotModel.append({
                            type: "toggle",
                            toggleId: toggleOptions[t].id,
                            listView: "fixed",
                            labelText: ""
                        });
                        break;
                    }
                }
            }
            if (countFixedToggles() >= fixedRowLength) break;
        }
        //% "Sliding Row"
        slotModel.append({ type: "label", labelText: qsTrId("id-sliding-row"), toggleId: "", listView: "" });
        for (i = 0; i < sliderTogglesArray.length; i++) {
            toggleId = sliderTogglesArray[i];
            if (toggleId && !isToggleInFixedRow(toggleId)) {
                toggle = findToggle(toggleId);
                if (toggle && toggle.available) {
                    slotModel.append({
                        type: "toggle",
                        toggleId: toggleId,
                        listView: "slider",
                        labelText: ""
                    });
                }
            }
        }
        for (i = 0; i < sliderTogglesArray.length; i++) {
            toggleId = sliderTogglesArray[i];
            if (toggleId && !isToggleInFixedRow(toggleId)) {
                toggle = findToggle(toggleId);
                if (toggle && !toggle.available) {
                    slotModel.append({
                        type: "toggle",
                        toggleId: toggleId,
                        listView: "slider",
                        labelText: ""
                    });
                }
            }
        }
        //% "Options"
        slotModel.append({ type: "label", labelText: qsTrId("id-options"), toggleId: "", listView: "" });
        //% "Battery Meter aligned to bottom?"
        slotModel.append({ type: "config", labelText: qsTrId("id-battery-bottom"), toggleId: "", listView: "" });
        //% "Enable colored battery?"
        slotModel.append({ type: "config", labelText: qsTrId("id-battery-colored"), toggleId: "", listView: "" });
        //% "Show battery charge animation?"
        slotModel.append({ type: "config", labelText: qsTrId("id-battery-animation"), toggleId: "", listView: "" });
        //% "Tap to cycle particle design"
        slotModel.append({ type: "cycler", labelText: qsTrId("id-particle-design"), toggleId: "", listView: "" });
        //% "Battery preview"
        slotModel.append({ type: "display", labelText: qsTrId("id-battery-preview"), toggleId: "", listView: "" });

        saveConfiguration();
        listLoader.active = true;
    }

    // Count the number of fixed toggles in the model
    function countFixedToggles() {
        var count = 0;
        for (var i = 1; i < slotModel.count; i++) {
            if (slotModel.get(i).type === "toggle" && slotModel.get(i).listView === "fixed") {
                count++;
            }
            if (slotModel.get(i).type === "label" && slotModel.get(i).labelText === qsTrId("id-sliding-row")) {
                break;
            }
        }
        return count;
    }

    // Check if a toggle is in the fixed row
    function isToggleInFixedRow(toggleId) {
        for (var i = 1; i < slotModel.count; i++) {
            var item = slotModel.get(i);
            if (item.type === "label" && item.labelText === qsTrId("id-sliding-row")) {
                break;
            }
            if (item.type === "toggle" && item.toggleId === toggleId) {
                return true;
            }
        }
        return false;
    }

    // Find the index of the slider label
    function findSliderLabelIndex() {
        for (var i = 0; i < slotModel.count; i++) {
            if (slotModel.get(i).type === "label" && slotModel.get(i).labelText === qsTrId("id-sliding-row")) {
                return i;
            }
        }
        return 3;
    }

    // Find the index of the options label
    function findOptionsLabelIndex() {
        for (var i = 0; i < slotModel.count; i++) {
            if (slotModel.get(i).type === "label" && slotModel.get(i).labelText === qsTrId("id-options")) {
                return i;
            }
        }
        return slotModel.count - 6;
    }

    // Ensure the slider label stays at the correct position
    function ensureSliderLabelPosition() {
        var sliderIndex = findSliderLabelIndex();
        if (sliderIndex !== 3) {
            slotModel.move(sliderIndex, 3, 1);
        }
    }

    // Validate drop position for drag-and-drop
    function isValidDropPosition(dropIndex) {
        var item = slotModel.get(dropIndex);
        if (item.type !== "toggle") {
            return false;
        }

        var sliderLabelIndex = findSliderLabelIndex();
        var optionsIndex = findOptionsLabelIndex();

        if (dropIndex === 0 || dropIndex === sliderLabelIndex || dropIndex >= optionsIndex) {
            return false;
        }

        var toggleSection = dropIndex < sliderLabelIndex ? "fixed" : "slider";
        var sectionStart = toggleSection === "fixed" ? 1 : sliderLabelIndex + 1;
        var sectionEnd = toggleSection === "fixed" ? sliderLabelIndex : optionsIndex;

        var firstUnavailableIndex = -1;
        for (var i = sectionStart; i < sectionEnd; i++) {
            if (slotModel.get(i).type === "toggle") {
                var toggle = findToggle(slotModel.get(i).toggleId);
                if (toggle && !toggle.available) {
                    firstUnavailableIndex = i;
                    break;
                }
            }
        }

        if (firstUnavailableIndex !== -1 && dropIndex >= firstUnavailableIndex) {
            return false;
        }

        return true;
    }

    // Save the current configuration
    function saveConfiguration() {
        var fixedArray = [];
        var sliderArray = [];

        for (var i = 1; i < slotModel.count; i++) {
            var item = slotModel.get(i);
            if (item.type === "label" && item.labelText === qsTrId("id-sliding-row")) {
                break;
            }
            if (item.type === "toggle") {
                fixedArray.push(item.toggleId);
            }
        }

        var sliderStart = findSliderLabelIndex() + 1;
        var optionsIndex = findOptionsLabelIndex();
        for (i = sliderStart; i < optionsIndex; i++) {
            item = slotModel.get(i);
            if (item.type === "toggle") {
                sliderArray.push(item.toggleId);
            }
        }

        fixedToggles.value = fixedArray;
        sliderToggles.value = sliderArray;
    }

    // Handle drag-and-drop movement
    function moveItems() {
        if (draggedItemIndex === -1 || targetIndex === -1 || draggedItemIndex === targetIndex) {
            return;
        }

        var sliderLabelIndex = findSliderLabelIndex();
        var optionsLabelIndex = findOptionsLabelIndex();

        if (targetIndex === 0 ||
            targetIndex === sliderLabelIndex ||
            targetIndex >= optionsLabelIndex ||
            !isValidDropPosition(targetIndex)) {
            return;
        }

        dragProxy.text = getToggleName(draggedToggleId);
        dragProxy.icon = getToggleIcon(draggedToggleId);

        if ((draggedItemIndex < sliderLabelIndex && targetIndex < sliderLabelIndex) ||
            (draggedItemIndex > sliderLabelIndex && targetIndex > sliderLabelIndex && targetIndex < optionsLabelIndex)) {
            slotModel.move(draggedItemIndex, targetIndex, 1);
            slotModel.setProperty(targetIndex, "listView", targetIndex < sliderLabelIndex ? "fixed" : "slider");
            draggedItemIndex = targetIndex;
        } else if ((draggedItemIndex > sliderLabelIndex && targetIndex < sliderLabelIndex) ||
                   (draggedItemIndex < sliderLabelIndex && targetIndex > sliderLabelIndex && targetIndex < optionsLabelIndex)) {
            slotModel.move(draggedItemIndex, targetIndex, 1);
            slotModel.setProperty(targetIndex, "listView", targetIndex < sliderLabelIndex ? "fixed" : "slider");
            draggedItemIndex = targetIndex;
            ensureSliderLabelPosition();
        }

        saveConfiguration();
        listLoader.item.forceLayout();
    }

    // Restore original order after drag cancellation
    function restoreOriginalOrder() {
        if (draggedItemIndex !== -1 && targetIndex !== -1 && draggedItemIndex !== targetIndex) {
            slotModel.move(draggedItemIndex, targetIndex, 1);
            slotModel.setProperty(targetIndex, "listView", targetIndex < findSliderLabelIndex() ? "fixed" : "slider");
            saveConfiguration();
        }
    }

    // Abort drag operation
    function abortDrag() {
        if (draggedItemIndex !== -1) {
            draggedItemIndex = -1;
            targetIndex = -1;
            dragProxy.visible = false;
            autoScrollTimer.scrollSpeed = 0;
            listLoader.item.forceLayout();
        }
    }

    Loader {
        id: listLoader
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        active: false
        sourceComponent: ListView {
            id: slotList
            clip: true
            interactive: draggedItemIndex === -1
            model: slotModel
            cacheBuffer: Dims.h(60)
            maximumFlickVelocity: 1000
            boundsBehavior: Flickable.DragAndOvershootBounds

            Component.onCompleted: {
                forceLayout();
            }

            header: Item {
                width: parent.width
                height: 0
            }

            footer: Item {
                width: parent.width
                height: rowHeight * 1.5
            }

            Timer {
                id: autoScrollTimer
                interval: 16
                repeat: true
                running: draggedItemIndex !== -1 && scrollSpeed !== 0
                property real scrollSpeed: 0
                property real scrollThreshold: height * 0.2

                onTriggered: {
                    if (draggedItemIndex === -1 || Math.abs(scrollSpeed) <= 0.1) {
                        scrollSpeed = 0;
                        return;
                    }

                    var newContentY = contentY + scrollSpeed;
                    var minContentY = 0
                    newContentY = Math.max(minContentY, Math.min(newContentY, contentHeight - height));
                    contentY = newContentY;
                }
            }

            displaced: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }

            add: Transition {
                NumberAnimation {
                    properties: "y,opacity"
                    from: 0
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }

            move: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }

            delegate: Item {
                id: delegateItem
                width: slotList.width
                height: type === "label" ? rowHeight :
                        type === "config" ? Math.max(rowHeight * 2, childrenRect.height) :
                        type === "cycler" ? Math.max(rowHeight * 2, childrenRect.height) :
                        type === "display" ? Math.max(rowHeight * 2, childrenRect.height) :
                        rowHeight
                property int visualIndex: index
                property bool isDragging: index === draggedItemIndex

                HighlightBar {
                    id: pressHighlight
                    anchors.fill: parent
                    visible: type === "toggle"
                    z: -1
                    forceOn: dragArea.pressed
                }

                Label {
                    visible: type === "label"
                    text: labelText
                    color: "#ffffff"
                    font.pixelSize: Dims.l(6)
                    font.italic: true
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        verticalCenter: parent.verticalCenter
                    }
                }

                LabeledSwitch {
                    visible: type === "config"
                    width: delegateItem.width
                    height: Math.max(rowHeight * 2, implicitHeight)
                    text: labelText
                    checked: {
                        if (labelText === qsTrId("id-battery-bottom")) return options.value.batteryBottom;
                        if (labelText === qsTrId("id-battery-animation")) return options.value.batteryAnimation;
                        if (labelText === qsTrId("id-battery-colored")) return options.value.batteryColored;
                        return false;
                    }
                    onCheckedChanged: {
                        var newOptions = Object.assign({}, options.value);
                        if (labelText === qsTrId("id-battery-bottom")) {
                            newOptions.batteryBottom = checked;
                        } else if (labelText === qsTrId("id-battery-animation")) {
                            newOptions.batteryAnimation = checked;
                        } else if (labelText === qsTrId("id-battery-colored")) {
                            newOptions.batteryColored = checked;
                        }
                        options.value = newOptions;
                    }
                }

                OptionCycler {
                    visible: type === "cycler"
                    width: delegateItem.width
                    height: Math.max(rowHeight * 2, implicitHeight)
                    title: qsTrId("id-particle-design")
                    configObject: options.value
                    configKey: "particleDesign"
                    valueArray: particleDesigns
                    currentValue: options.value.particleDesign
                    opacity: options.value.batteryAnimation ? 1.0 : 0.5
                    onValueChanged: {
                        var newOptions = Object.assign({}, options.value);
                        newOptions.particleDesign = value;
                        options.value = newOptions;
                    }
                }

                ValueMeter {
                    id: valueMeter
                    visible: type === "display"
                    width: Dims.l(28) * 1.8
                    height: Dims.l(8)
                    valueLowerBound: 0
                    valueUpperBound: 100
                    value: batteryChargePercentage.percent
                    isIncreasing: mceChargerType.type != MceChargerType.None
                    enableAnimations: options.value.batteryAnimation
                    enableColoredFill: options.value.batteryColored
                    particleDesign: options.value.particleDesign
                    fillColor: {
                        if (!options.value.batteryColored) return Qt.rgba(1, 1, 1, 0.3)
                        var percent = batteryChargePercentage.percent
                        if (percent > 50) return Qt.rgba(0, 1, 0, 0.3)
                        if (percent > 20) {
                            var t = (50 - percent) / 30
                            return Qt.rgba(t, 1 - (t * 0.35), 0, 0.3)
                        }
                        var t = (20 - percent) / 20
                        return Qt.rgba(1, 0.65 * (1 - t), 0, 0.3)
                    }
                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                        topMargin: Dims.l(2)
                    }
                }

                Rectangle {
                    width: delegateItem.width
                    height: rowHeight
                    opacity: 0
                    visible: isDragging && type === "toggle"
                }

                Rectangle {
                    id: iconRectangle
                    width: Dims.w(16)
                    height: Dims.w(16)
                    radius: width / 2
                    color: "#222222"
                    opacity: {
                        if (toggleId === "") return 0;
                        var toggle = findToggle(toggleId);
                        if (!toggle || !toggle.available) return 0.2;
                        return toggleEnabled.value[toggleId] ? 0.7 : 0.3;
                    }
                    visible: type === "toggle" && toggleId !== "" && !isDragging
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: Dims.l(14)
                    }
                    Icon {
                        id: toggleIcon
                        name: getToggleIcon(toggleId)
                        width: Dims.w(10)
                        height: Dims.w(10)
                        anchors.centerIn: parent
                        color: "#ffffff"
                        opacity: {
                            if (toggleId === "") return 0;
                            var toggle = findToggle(toggleId);
                            if (!toggle || !toggle.available) return 0.4;
                            return toggleEnabled.value[toggleId] ? 1.0 : 0.8;
                        }
                        visible: toggleId !== ""
                    }
                }

                Label {
                    text: getToggleName(toggleId)
                    color: "#ffffff"
                    opacity: {
                        if (toggleId === "") return 0;
                        var toggle = findToggle(toggleId);
                        if (!toggle || !toggle.available) return 0.5;
                        return toggleEnabled.value[toggleId] ? 1.0 : 0.6;
                    }
                    visible: type === "toggle" && toggleId !== "" && !isDragging
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: iconRectangle.right
                        leftMargin: Dims.l(4)
                    }
                    font {
                        pixelSize: Dims.l(8)
                        styleName: "Light"
                    }
                }

                Timer {
                    id: longPressTimer
                    interval: 500
                    repeat: false
                    property bool dragPending: false

                    onTriggered: {
                        if (!dragPending || type !== "toggle") return;
                        dragPending = false;

                        var toggle = findToggle(toggleId);
                        if (toggle && toggle.available) {
                            draggedItemIndex = index;
                            targetIndex = index;
                            draggedToggleId = toggleId;
                            var itemPos = delegateItem.mapToItem(slotList, 0, 0);
                            dragProxy.x = 0;
                            dragProxy.y = itemPos.y;
                            dragProxy.text = getToggleName(toggleId);
                            dragProxy.icon = getToggleIcon(toggleId);
                            dragProxy.visible = true;
                            dragYOffset = dragArea.startPos.y;
                        }
                    }
                }

                MouseArea {
                    id: dragArea
                    anchors {
                        left: type === "toggle" ? iconRectangle.left : parent.left
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    enabled: {
                        if (isDragging || type !== "toggle") return false;
                        var toggle = findToggle(toggleId);
                        return toggle && toggle.available;
                    }
                    property point startPos: Qt.point(0, 0)
                    property real pressStartTime: 0

                    onPressed: {
                        startPos = Qt.point(mouse.x, mouse.y);
                        pressStartTime = new Date().getTime();
                        longPressTimer.dragPending = true;
                        longPressTimer.start();
                    }

                    onPositionChanged: {
                        if (!longPressTimer.running && draggedItemIndex === -1) {
                            if (Math.abs(mouse.x - startPos.x) > 20 || Math.abs(mouse.y - startPos.y) > 20) {
                                longPressTimer.stop();
                            }
                            return;
                        }

                        if (draggedItemIndex !== -1) {
                            var pos = mapToItem(slotList, mouse.x, mouse.y);
                            dragProxy.y = pos.y - dragYOffset;

                            var distFromTop = pos.y;
                            var distFromBottom = slotList.height - pos.y;
                            if (distFromTop < autoScrollTimer.scrollThreshold) {
                                autoScrollTimer.scrollSpeed = -25 * (1 - distFromTop / autoScrollTimer.scrollThreshold);
                            } else if (distFromBottom < autoScrollTimer.scrollThreshold) {
                                autoScrollTimer.scrollSpeed = 25 * (1 - distFromBottom / autoScrollTimer.scrollThreshold);
                            } else {
                                autoScrollTimer.scrollSpeed = 0;
                            }

                            var dropY = pos.y + slotList.contentY;

                            if (dropY >= 0) {
                                var itemUnder = slotList.itemAt(slotList.width / 2, dropY);
                                if (itemUnder && itemUnder.visualIndex !== undefined) {
                                    var dropIndex = itemUnder.visualIndex;
                                    var optionsIndex = findOptionsLabelIndex();
                                    var sliderLabelIndex = findSliderLabelIndex();

                                    if (dropIndex > sliderLabelIndex && dropIndex >= optionsIndex - 1) {
                                        dropIndex -= 1;
                                    }

                                    if (dropIndex !== draggedItemIndex && isValidDropPosition(dropIndex)) {
                                        var targetY = itemUnder.y + itemUnder.height / 2;
                                        if (dropY < targetY && dropIndex > 0) {
                                            var prevItem = slotModel.get(dropIndex - 1);
                                            if (prevItem.type !== "label" &&
                                                ((prevItem.listView === "fixed" && dropIndex < sliderLabelIndex) ||
                                                 (prevItem.listView === "slider" && dropIndex > sliderLabelIndex))) {
                                                dropIndex -= 1;
                                            }
                                        }

                                        if (isValidDropPosition(dropIndex) && dropIndex !== targetIndex) {
                                            targetIndex = dropIndex;
                                            moveItems();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    onReleased: {
                        var pressDuration = new Date().getTime() - pressStartTime;

                        if (draggedItemIndex !== -1) {
                            var pos = mapToItem(slotList, mouse.x, mouse.y);
                            var dropY = pos.y + slotList.contentY;

                            if (dropY >= 0) {
                                var itemUnder = slotList.itemAt(slotList.width / 2, dropY);
                                if (itemUnder && itemUnder.visualIndex !== undefined) {
                                    var dropIndex = itemUnder.visualIndex;
                                    var optionsIndex = findOptionsLabelIndex();
                                    var sliderLabelIndex = findSliderLabelIndex();

                                    if (dropIndex > sliderLabelIndex && dropIndex >= optionsIndex - 1) {
                                        dropIndex -= 1;
                                    }

                                    if (dropIndex !== draggedItemIndex && isValidDropPosition(dropIndex)) {
                                        targetIndex = dropIndex;
                                        moveItems();
                                    } else {
                                        abortDrag();
                                    }
                                } else {
                                    abortDrag();
                                }
                            } else {
                                abortDrag();
                            }

                            dragProxy.visible = false;
                            draggedItemIndex = -1;
                            targetIndex = -1;
                            autoScrollTimer.scrollSpeed = 0;
                            longPressTimer.stop();
                        } else if (type === "toggle" && toggleId && pressDuration < 500) {
                            longPressTimer.stop();
                            var newEnabled = Object.assign({}, toggleEnabled.value);
                            var isFixedToggle = isToggleInFixedRow(toggleId);
                            var sliderLabelIndex = findSliderLabelIndex();
                            var optionsLabelIndex = findOptionsLabelIndex();
                            var fixedActiveCount = 0;
                            for (var i = 1; i < sliderLabelIndex; i++) {
                                var item = slotModel.get(i);
                                if (item.type === "toggle" && toggleEnabled.value[item.toggleId]) {
                                    fixedActiveCount++;
                                }
                            }
                            var sliderActiveCount = 0;
                            for (i = sliderLabelIndex + 1; i < optionsLabelIndex; i++) {
                                item = slotModel.get(i);
                                if (item.type === "toggle" && toggleEnabled.value[item.toggleId]) {
                                    sliderActiveCount++;
                                }
                            }
                            if (newEnabled[toggleId]) {
                                if (isFixedToggle && fixedActiveCount <= 1) {
                                    return;
                                }
                                if (!isFixedToggle && sliderActiveCount <= 2) {
                                    return;
                                }
                            }
                            newEnabled[toggleId] = !newEnabled[toggleId];
                            toggleEnabled.value = newEnabled;
                        } else {
                            longPressTimer.stop();
                        }
                    }

                    onCanceled: {
                        longPressTimer.stop();
                        autoScrollTimer.scrollSpeed = 0;
                        abortDrag();
                    }
                }
            }
        }
    }

    Item {
        id: dragProxy
        visible: false
        z: 10
        width: Dims.w(100)
        height: rowHeight
        property string text: ""
        property string icon: ""

        HighlightBar {
            anchors.fill: parent
            forceOn: dragProxy.visible
        }

        Rectangle {
            id: dragIconRect
            width: Dims.w(16)
            height: Dims.w(16)
            radius: width / 2
            color: "#222222"
            opacity: 0.8
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: Dims.l(14)
            }
            Icon {
                name: dragProxy.icon
                width: Dims.w(10)
                height: Dims.w(10)
                anchors.centerIn: parent
                color: "#ffffff"
                visible: dragProxy.icon !== ""
            }
        }

        Label {
            text: dragProxy.text
            color: "#ffffff"
            opacity: 0.9
            anchors {
                verticalCenter: parent.verticalCenter
                left: dragIconRect.right
                leftMargin: Dims.l(4)
            }
            font {
                pixelSize: Dims.l(8)
                styleName: "Light"
            }
        }
    }
}
