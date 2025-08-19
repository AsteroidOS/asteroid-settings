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
    id: quickPanelPage

    // Battery status components for the ValueMeter
    MceBatteryLevel { id: batteryChargePercentage }
    MceBatteryState { id: batteryChargeState }
    MceChargerType { id: mceChargerType }

    // ConfigurationValue for toggle arrays
    ConfigurationValue {
        id: fixedToggles
        key: "/desktop/asteroid/quickpanel/fixed"
        defaultValue: ["lockButton", "settingsButton"]
    }

    ConfigurationValue {
        id: sliderToggles
        key: "/desktop/asteroid/quickpanel/slider"
        defaultValue: [
            "brightnessToggle",
            "bluetoothToggle",
            "hapticsToggle",
            "wifiToggle",
            "soundToggle",
            "cinemaToggle",
            "aodToggle",
            "powerOffToggle",
            "rebootToggle",
            "musicButton",
            "flashlightButton"
        ]
    }

    ConfigurationValue {
        id: toggleEnabled
        key: "/desktop/asteroid/quickpanel/enabled"
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
        key: "/desktop/asteroid/quickpanel/options"
        defaultValue: {
            "batteryBottom": true,
            "batteryAnimation": true,
            "batteryColored": false,
            "particleDesign": "diamonds"
        }
    }

    // Available toggle options with translatable names and icons
    property var toggleOptions: []

    // Layout properties
    property real rowHeight: Dims.h(18)
    property int draggedItemIndex: -1
    property int targetIndex: -1
    property int fixedRowLength: 2
    property real dragYOffset: 0
    property var draggedToggle: null
    property var particleDesigns: ["diamonds", "bubbles", "logos", "flashes"]

    Component.onCompleted: {
        populateToggleOptions();
    }

    function populateToggleOptions() {

        //% "Lock Button"
        toggleOptions["lockButton"] = ({ name: qsTrId("id-toggle-lock"), icon: "ios-unlock"});
        //% "Settings"
        toggleOptions["settingsButton"] = ({ name: qsTrId("id-toggle-settings"), icon: "ios-settings"});
        //% "Brightness"
        toggleOptions["brightnessToggle"] = ({name: qsTrId("id-toggle-brightness"), icon: "ios-sunny"});
        //% "Bluetooth"
        toggleOptions["bluetoothToggle"] = ({ name: qsTrId("id-toggle-bluetooth"), icon: "ios-bluetooth"});
        //% "Vibration"
        toggleOptions["hapticsToggle"] = ({ name: qsTrId("id-toggle-haptics"), icon: "ios-watch-vibrating"});
        if (DeviceSpecs.hasWlan) {
            //% "Wifi Toggle"
            toggleOptions["wifiToggle"] = ({ name: qsTrId("id-toggle-wifi"), icon: "ios-wifi-outline"});
        }
        if (DeviceSpecs.hasSpeaker) {
            //% "Mute Sound"
            toggleOptions["soundToggle"] = ({ name: qsTrId("id-toggle-sound"), icon: "ios-sound-indicator-high"});
        }
        //% "Cinema Mode"
        toggleOptions["cinemaToggle"] = ({ name: qsTrId("id-toggle-cinema"), icon: "ios-film-outline"});
        //% "AoD Toggle"
        toggleOptions["aodToggle"] = ({ name: qsTrId("id-always-on-display"), icon: "ios-watch-aod-on"});
        //% "Poweroff"
        toggleOptions["powerOffToggle"] = ({ name: qsTrId("id-toggle-power-off"), icon: "ios-power"});
        //% "Reboot"
        toggleOptions["rebootToggle"] = ({ name: qsTrId("id-toggle-reboot"), icon: "ios-refresh"});
        //% "Music"
        toggleOptions["musicButton"] = ({ name: qsTrId("id-toggle-music"), icon: "ios-musical-notes-outline"});
        //% "Flashlight"
        toggleOptions["flashlightButton"] = ({ name: qsTrId("id-toggle-flashlight"), icon: "ios-bulb-outline"});
    }

    ListModel {
        id: slotModel
        Component.onCompleted: {
            refreshModel();
        }
    }

    // Populate the model with fixed and slider toggles
    function refreshModel() {
        slotModel.clear();

        const fixedTogglesArray = fixedToggles.value;
        const sliderTogglesArray = sliderToggles.value;

        //% "Fixed Row"
        slotModel.append({ type: "label", labelText: qsTrId("id-fixed-row"), toggleId: "", listView: "" });
        // Adds available fixed row toggles first
        for (let i = 0; i < fixedTogglesArray.length && i < fixedRowLength; i++) {
            const toggleId = fixedTogglesArray[i];
            const toggle = toggleOptions[toggleId];
            if (!toggle) continue;

            slotModel.append({
                type: "toggle",
                toggleId: toggleId,
                listView: "fixed",
                labelText: "",
                toggle: toggle
            });
        }

        // In case less than fixedRowLength, fill with any other toggle
        const missingFixedRowToggles = fixedRowLength - countFixedToggles();
        for (let i = 0; i < missingFixedRowToggles; i++) {
            for (let t = 0; t < toggleOptions.length; t++) {
                const toggleId = toggleOptions[t].id;
                if (isToggleInRow(toggleId)) continue;
                const toggle = toggleOptions[toggleId];
                if (!toggle) continue;

                slotModel.append({
                    type: "toggle",
                    toggleId: toggleId,
                    listView: "fixed",
                    labelText: "",
                    toggle: toggle
                });
                break;
            }
        }
        //% "Sliding Row"
        slotModel.append({ type: "label", labelText: qsTrId("id-sliding-row"), toggleId: "", listView: "" });
        // Adds available slider row toggles first. Ensure it doesn't already exist in the fixed row
        for (let i = 0; i < sliderTogglesArray.length; i++) {
            const toggleId = sliderTogglesArray[i];

            if (!toggleId || isToggleInRow(toggleId)) continue;

            const toggle = toggleOptions[toggleId];
            if (!toggle) continue;

            slotModel.append({
                type: "toggle",
                toggleId: toggleId,
                listView: "slider",
                labelText: "",
                toggle: toggle
            });
        }

        // Adds remaining toggles to sliding row
        for (let t = 0; t < toggleOptions.length; t++) {
            const toggleId = toggleOptions[t].id;
            if (isToggleInRow(toggleId)) continue;

            const toggle = toggleOptions[toggleId];
            if (!toggle) continue;

            slotModel.append({
                type: "toggle",
                toggleId: toggleId,
                listView: "slider",
                labelText: "",
                toggle: toggle
            });
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
        let count = 0;
        for (let i = 1; i < slotModel.count; i++) {
            const item = slotModel.get(i);
            if (item.type === "toggle" && item.listView === "fixed") {
                count++;
            }
            if (item.type === "label" && item.labelText === qsTrId("id-sliding-row")) {
                break;
            }
        }
        return count;
    }

    // Check if a toggle is in the fixed row
    function isToggleInFixedRow(toggleId) {
        for (let i = 1; i < slotModel.count; i++) {
            const item = slotModel.get(i);
            if (item.type === "label" && item.labelText === qsTrId("id-sliding-row")) {
                break;
            }
            if (item.type === "toggle" && item.toggleId === toggleId) {
                return true;
            }
        }
        return false;
    }

    // Check if a toggle is in any row
    function isToggleInRow(toggleId) {
        for (let i = 1; i < slotModel.count; i++) {
            const item = slotModel.get(i);

            if (item.type !== "toggle") {
                continue;
            }

            if (item.toggleId !== toggleId) {
                continue;
            }

            return true;
        }
        return false;
    }

    // Find the index of the slider label
    function findSliderLabelIndex() {
        for (let i = 0; i < slotModel.count; i++) {
            const item = slotModel.get(i);
            if (item.type === "label" && item.labelText === qsTrId("id-sliding-row")) {
                return i;
            }
        }
        return null;
    }

    // Find the index of the options label
    function findOptionsLabelIndex() {
        for (let i = 0; i < slotModel.count; i++) {
            const item = slotModel.get(i);
            if (item.type === "label" && item.labelText === qsTrId("id-options")) {
                return i;
            }
        }
        return null;
    }

    // Ensure the slider label stays at the correct position
    function ensureSliderLabelPosition() {
        const sliderIndex = findSliderLabelIndex();
        if (sliderIndex === null) return;

        // Ensure slider label is right after the fixed row
        slotModel.move(sliderIndex, fixedRowLength + 1, 1);
    }

    // Validate drop position for drag-and-drop
    function isValidDropPosition(dropIndex) {
        const item = slotModel.get(dropIndex);
        if (item.type !== "toggle") {
            return false;
        }

        const sliderLabelIndex = findSliderLabelIndex();
        const optionsIndex = findOptionsLabelIndex();

        if (dropIndex === 0 || dropIndex === sliderLabelIndex || dropIndex >= optionsIndex) {
            return false;
        }

        return true;
    }

    // Save the current configuration
    function saveConfiguration() {
        let fixedArray = [];
        let sliderArray = [];

        for (let i = 1; i < slotModel.count; i++) {
            const item = slotModel.get(i);
            if (item.type === "label" && item.labelText === qsTrId("id-sliding-row")) {
                break;
            }
            if (item.type === "toggle") {
                fixedArray.push(item.toggleId);
            }
        }

        const sliderStart = findSliderLabelIndex() + 1;
        const optionsIndex = findOptionsLabelIndex();
        for (let i = sliderStart; i < optionsIndex; i++) {
            const item = slotModel.get(i);
            if (item.type !== "toggle") continue;

            sliderArray.push(item.toggleId);
        }

        fixedToggles.value = fixedArray;
        sliderToggles.value = sliderArray;
    }

    // Handle drag-and-drop movement
    function moveItems() {
        if (draggedItemIndex === -1 || targetIndex === -1 || draggedItemIndex === targetIndex) {
            return;
        }

        const sliderLabelIndex = findSliderLabelIndex();
        const optionsLabelIndex = findOptionsLabelIndex();

        if (targetIndex === 0 ||
            targetIndex === sliderLabelIndex ||
            targetIndex >= optionsLabelIndex ||
            !isValidDropPosition(targetIndex)) {
            return;
        }

        dragProxy.text = draggedToggle.name;
        dragProxy.icon = draggedToggle.icon;

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
        if (draggedItemIndex === targetIndex || draggedItemIndex === -1) return;

        slotModel.move(draggedItemIndex, targetIndex, 1);
        slotModel.setProperty(targetIndex, "listView", targetIndex < findSliderLabelIndex() ? "fixed" : "slider");
        saveConfiguration();
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

                    const newContentY = contentY + scrollSpeed;
                    contentY = Math.max(0, Math.min(newContentY, contentHeight - height));
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
                        const newOptions = Object.assign({}, options.value);
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
                        const newOptions = Object.assign({}, options.value);
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
                        const percent = batteryChargePercentage.percent
                        if (percent > 50) return Qt.rgba(0, 1, 0, 0.3)
                        if (percent > 20) {
                            const t = (50 - percent) / 30
                            return Qt.rgba(t, 1 - (t * 0.35), 0, 0.3)
                        }
                        const t = (20 - percent) / 20
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
                    opacity: toggleId ? (toggleEnabled.value[toggleId] ? 0.7 : 0.3) : 0;
                    visible: type === "toggle" && toggleId !== "" && !isDragging
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: Dims.l(14)
                    }
                    Icon {
                        id: toggleIcon
                        name: toggle ? toggle.icon : null
                        width: Dims.w(10)
                        height: Dims.w(10)
                        anchors.centerIn: parent
                        color: "#ffffff"
                        opacity: toggleId ? (toggleEnabled.value[toggleId] ? 1.0 : 0.8) : 0;
                        visible: toggleId !== ""
                    }
                }

                Label {
                    text: toggle ? toggle.name : null
                    color: "#ffffff"
                    opacity: toggleId ? (toggleEnabled.value[toggleId] ? 1.0 : 0.6) : 0;
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

                        draggedItemIndex = index;
                        targetIndex = index;
                        draggedToggle = toggle;
                        const itemPos = delegateItem.mapToItem(slotList, 0, 0);
                        dragProxy.x = 0;
                        dragProxy.y = itemPos.y;
                        dragProxy.text = toggle.name;
                        dragProxy.icon = toggle.icon;
                        dragProxy.visible = true;
                        dragYOffset = dragArea.startPos.y;
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
                    enabled: !isDragging && type === "toggle"
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

                        if (draggedItemIndex === -1) return;

                        const pos = mapToItem(slotList, mouse.x, mouse.y);
                        dragProxy.y = pos.y - dragYOffset;

                        const distFromTop = pos.y;
                        const distFromBottom = slotList.height - pos.y;
                        if (distFromTop < autoScrollTimer.scrollThreshold) {
                            autoScrollTimer.scrollSpeed = -25 * (1 - distFromTop / autoScrollTimer.scrollThreshold);
                        } else if (distFromBottom < autoScrollTimer.scrollThreshold) {
                            autoScrollTimer.scrollSpeed = 25 * (1 - distFromBottom / autoScrollTimer.scrollThreshold);
                        } else {
                            autoScrollTimer.scrollSpeed = 0;
                        }

                        const dropY = pos.y + slotList.contentY;

                        if (dropY < 0) return;

                        const itemUnder = slotList.itemAt(slotList.width / 2, dropY);
                        if (!itemUnder || itemUnder.visualIndex === undefined) return;

                        let dropIndex = itemUnder.visualIndex;
                        const optionsIndex = findOptionsLabelIndex();
                        const sliderLabelIndex = findSliderLabelIndex();

                        if (dropIndex > sliderLabelIndex && dropIndex >= optionsIndex - 1) {
                            dropIndex -= 1;
                        }

                        if (dropIndex !== draggedItemIndex && isValidDropPosition(dropIndex)) {
                            const targetY = itemUnder.y + itemUnder.height / 2;
                            if (dropY < targetY && dropIndex > 0) {
                                const prevItem = slotModel.get(dropIndex - 1);
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

                    // Abort drag operation
                    function abortDrag() {
                        if (draggedItemIndex === -1) return;

                        draggedItemIndex = -1;
                        targetIndex = -1;
                        dragProxy.visible = false;
                        autoScrollTimer.scrollSpeed = 0;
                        listLoader.item.forceLayout();
                    }

                    function handleDropReleased(dropY) {
                        if (dropY < 0) {
                            abortDrag();
                            return;
                        }

                        const itemUnder = slotList.itemAt(slotList.width / 2, dropY);
                        if (!itemUnder || itemUnder.visualIndex === undefined) {
                            abortDrag();
                            return;
                        }

                        const dropIndex = itemUnder.visualIndex;
                        const optionsIndex = findOptionsLabelIndex();
                        const sliderLabelIndex = findSliderLabelIndex();

                        if (dropIndex > sliderLabelIndex && dropIndex >= optionsIndex - 1) {
                            dropIndex -= 1;
                        }

                        if (dropIndex === draggedItemIndex || !isValidDropPosition(dropIndex)) {
                            abortDrag();
                            return;
                        }

                        targetIndex = dropIndex;
                        moveItems();
                    }

                    onReleased: {
                        const pressDuration = new Date().getTime() - pressStartTime;

                        longPressTimer.stop();

                        if (draggedItemIndex !== -1) {
                            const pos = mapToItem(slotList, mouse.x, mouse.y);
                            const dropY = pos.y + slotList.contentY;

                            handleDropReleased(dropY);

                            dragProxy.visible = false;
                            draggedItemIndex = -1;
                            targetIndex = -1;
                            autoScrollTimer.scrollSpeed = 0;
                        } else if (type === "toggle" && toggleId && pressDuration < 500) {
                            const newEnabled = Object.assign({}, toggleEnabled.value);
                            const isFixedToggle = isToggleInFixedRow(toggleId);
                            const sliderLabelIndex = findSliderLabelIndex();
                            const optionsLabelIndex = findOptionsLabelIndex();
                            let fixedActiveCount = 0;
                            for (let i = 1; i < sliderLabelIndex; i++) {
                                const item = slotModel.get(i);
                                if (item.type === "toggle" && toggleEnabled.value[item.toggleId]) {
                                    fixedActiveCount++;
                                }
                            }
                            let sliderActiveCount = 0;
                            for (let i = sliderLabelIndex + 1; i < optionsLabelIndex; i++) {
                                const item = slotModel.get(i);
                                if (item.type === "toggle" && toggleEnabled.value[item.toggleId]) {
                                    sliderActiveCount++;
                                }
                            }
                            if (newEnabled[toggleId]) {
                                // Ensure that a toggle is always enabled
                                if (isFixedToggle && fixedActiveCount <= 1) {
                                    return;
                                }
                                if (!isFixedToggle && sliderActiveCount <= 2) {
                                    return;
                                }
                            }
                            newEnabled[toggleId] = !newEnabled[toggleId];
                            toggleEnabled.value = newEnabled;
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
