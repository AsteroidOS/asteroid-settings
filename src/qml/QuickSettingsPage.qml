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
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import Nemo.Configuration 1.0

Item {
    id: settingsPage

    // ConfigurationValue for toggle arrays
    ConfigurationValue {
        id: fixedToggles
        key: "/desktop/asteroid/quicksettings/fixed"
        defaultValue: ["lockButton", "settingsButton"]
    }

    ConfigurationValue {
        id: sliderToggles
        key: "/desktop/asteroid/quicksettings/slider"
        defaultValue: ["brightnessToggle", "bluetoothToggle", "hapticsToggle", "wifiToggle", "soundToggle", "cinemaToggle"]
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
            "cinemaToggle": true
        }
    }

    ConfigurationValue {
        id: options
        key: "/desktop/asteroid/quicksettings/options"
        defaultValue: {
            "batteryBottom": true,
            "batteryAnimation": true,
            "batteryColored": false
        }
    }

    // Toggle definitions
    property var toggleOptions: [
        //% "Lock Button"
        { id: "lockButton", name: qsTrId("id-toggle-lock"), icon: "ios-unlock", available: true },
        //% "Settings Link"
        { id: "settingsButton", name: qsTrId("id-toggle-settings"), icon: "ios-settings", available: true },
        //% "Brightness"
        { id: "brightnessToggle", name: qsTrId("id-toggle-brightness"), icon: "ios-sunny", available: true },
        //% "Bluetooth"
        { id: "bluetoothToggle", name: qsTrId("id-toggle-bluetooth"), icon: "ios-bluetooth", available: true },
        //% "Vibration"
        { id: "hapticsToggle", name: qsTrId("id-toggle-haptics"), icon: "ios-watch-vibrating", available: true },
        //% "WiFi"
        { id: "wifiToggle", name: qsTrId("id-toggle-wifi"), icon: "ios-wifi-outline", available: DeviceInfo.hasWlan },
        //% "Mute Sound"
        { id: "soundToggle", name: qsTrId("id-toggle-sound"), icon: "ios-sound-indicator-high", available: DeviceInfo.hasSpeaker },
        //% "Cinema Mode"
        { id: "cinemaToggle", name: qsTrId("id-toggle-cinema"), icon: "ios-film-outline", available: true }
    ]

    property string rowHeight: Dims.h(16)
    property string labelHeight: rowHeight * 0.5
    property int draggedItemIndex: -1  // The index of the item being dragged
    property int targetIndex: -1       // The index of the item will be dropped
    property int fixedRowLength: 2 // Fixed to two top slots

    // Helper functions to replace Array.find
    function findToggle(toggleId) {
        for (var i = 0; i < toggleOptions.length; i++) {
            if (toggleOptions[i].id === toggleId) {
                return toggleOptions[i];
            }
        }
        return null;
    }

    function getToggleName(toggleId) {
        var toggle = findToggle(toggleId);
        return toggle ? toggle.name : "";
    }

    function getToggleIcon(toggleId) {
        var toggle = findToggle(toggleId);
        return toggle ? toggle.icon : "";
    }

    // Keep original data for reordering
    property var originalData: []

    function storeOriginalData() {
        originalData = [];
        for (var i = 0; i < slotModel.count; i++) {
            var item = slotModel.get(i);
            originalData.push({
                type: item.type,
                toggleId: item.type === "toggle" ? item.toggleId : "",
                listView: item.type === "toggle" ? item.listView : "",
                labelText: item.type === "label" || item.type === "config" ? item.labelText : ""
            });
        }
    }

    ListModel {
        id: slotModel

        Component.onCompleted: {
            slotModel.clear();
            // Fixed row
            slotModel.append({ type: "label", labelText: qsTrId("id-fixed-row"), toggleId: "", listView: "" });
            for (var i = 0; i < fixedToggles.value.length; i++) {
                if (fixedToggles.value[i]) {
                    slotModel.append({ type: "toggle", toggleId: fixedToggles.value[i], listView: "fixed", labelText: "" });
                }
            }
            // Slider row
            slotModel.append({ type: "label", labelText: qsTrId("id-sliding-row"), toggleId: "", listView: "" });
            for (i = 0; i < sliderToggles.value.length; i++) {
                if (sliderToggles.value[i]) {
                    slotModel.append({ type: "toggle", toggleId: sliderToggles.value[i], listView: "slider", labelText: "" });
                }
            }
            // Append unavailable toggles if not already included
            var allToggles = ["wifiToggle", "soundToggle"];
            for (i = 0; i < allToggles.length; i++) {
                var toggleId = allToggles[i];
                var toggle = findToggle(toggleId);
                if (toggle && !toggle.available) {
                    var exists = false;
                    for (var j = 0; j < slotModel.count; j++) {
                        if (slotModel.get(j).toggleId === toggleId) {
                            exists = true;
                            break;
                        }
                    }
                    if (!exists) {
                        slotModel.append({ type: "toggle", toggleId: toggleId, listView: "slider", labelText: "" });
                    }
                }
            }
            // Options
            slotModel.append({ type: "label", labelText: qsTrId("id-options"), toggleId: "", listView: "" });
            slotModel.append({ type: "config", labelText: qsTrId("id-battery-bottom"), toggleId: "", listView: "" });
            slotModel.append({ type: "config", labelText: qsTrId("id-battery-animation"), toggleId: "", listView: "" });
            slotModel.append({ type: "config", labelText: qsTrId("id-battery-colored"), toggleId: "", listView: "" });
            storeOriginalData();
        }
    }

    ListView {
        id: slotList
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: parent.height
        clip: true
        interactive: draggedItemIndex === -1
        model: slotModel
        cacheBuffer: rowHeight * 10 // Increase cache to stabilize delegate recycling
        boundsBehavior: Flickable.StopAtBounds // Prevent overscrolling issues

        header: Item {
            width: parent ? parent.width : 0 // Safe parent access
            height: title.height
        }

        footer: Item {
            width: parent ? parent.width : 0 // Safe parent access
            height: rowHeight * 1.5
        }

        onContentYChanged: {
            if (draggedItemIndex !== -1 && !slotList.itemAt(0, contentY + height/2)) {
                abortDrag();
            }
        }

        onMovementStarted: {
            if (draggedItemIndex !== -1) {
                abortDrag();
            }
        }

        Timer {
            id: scrollTimer
            interval: 16
            repeat: true
            running: draggedItemIndex !== -1

            onTriggered: {
                if (draggedItemIndex === -1 || !dragProxy || draggedItemIndex >= slotModel.count) {
                    running = false;
                    return;
                }

                var dragY = safeGet(dragProxy, "y", 0);

                // Keep automatic scrolling functionality
                if (dragY < slotList.height * 0.2) {
                    var newContentY = Math.max(0, slotList.contentY - 5);
                    if (slotList.contentY !== newContentY) {
                        slotList.contentY = newContentY;
                    }
                } else if (dragY > slotList.height * 0.8) {
                    var maxScroll = Math.max(0, slotList.contentHeight - slotList.height);
                    newContentY = Math.min(maxScroll, slotList.contentY + 5);
                    if (slotList.contentY !== newContentY) {
                        slotList.contentY = newContentY;
                    }
                }

                if (draggedItemIndex === -1) return;

                var dragCenterY = dragY + safeGet(dragProxy, "height", rowHeight) / 2;
                var adjustedY = slotList.contentY + dragCenterY;

                if (adjustedY < 0 || adjustedY >= slotList.contentHeight) {
                    return;
                }

                var firstItemY = slotList.contentY;
                var lastItemIndex = slotModel.count - 1;
                var lastItemY = lastItemIndex * rowHeight;
                if (slotModel.get(lastItemIndex).type === "label") {
                    lastItemY -= (rowHeight - labelHeight);
                }
                lastItemY += slotList.contentY;

                if (adjustedY < firstItemY || adjustedY > lastItemY) {
                    return;
                }

                try {
                    var item = slotList.itemAt(0, adjustedY);
                    if (item && item.visualIndex !== undefined) {
                        var newTargetIndex = item.visualIndex;

                        // Find Options label index
                        var optionsLabelIndex = -1;
                        for (var i = 0; i < slotModel.count; i++) {
                            if (slotModel.get(i).type === "label" && slotModel.get(i).labelText === qsTrId("id-options")) {
                                optionsLabelIndex = i;
                                break;
                            }
                        }

                        // Prevent dropping on or below the Options label
                        if (newTargetIndex === 0 || newTargetIndex === 3 ||
                            newTargetIndex === slotModel.count - 2 || newTargetIndex === slotModel.count - 1 ||
                            (optionsLabelIndex !== -1 && newTargetIndex >= optionsLabelIndex)) {
                            return;
                        }

                        if (newTargetIndex !== targetIndex && newTargetIndex !== -1) {
                            targetIndex = newTargetIndex;
                            moveItems();
                        }
                    }
                } catch (e) {
                    abortDrag();
                }
            }
        }

        displaced: Transition {
            NumberAnimation {
                properties: "y"
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        delegate: Item {
            id: delegateItem
            width: slotList ? slotList.width : 0
            height: type === "label" ? labelHeight : type === "config" ? Math.max(rowHeight * 2, delegateItem.childrenRect.height) : rowHeight
            property int visualIndex: index
            property bool isDragging: index === draggedItemIndex

            Rectangle {
                id: pressHighlight
                width: delegateItem.width
                height: rowHeight
                color: "#222222"
                opacity: 0
                visible: type === "toggle"
                z: -1

                Behavior on opacity {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Label {
                visible: type === "label"
                text: labelText
                color: "#ffffff"
                font.pixelSize: Dims.l(5)
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
                    if (labelText === qsTrId("id-battery-bottom")) {
                        return options.value.batteryBottom;
                    } else if (labelText === qsTrId("id-battery-animation")) {
                        return options.value.batteryAnimation;
                    } else if (labelText === qsTrId("id-battery-colored")) {
                        return options.value.batteryColored;
                    }
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

            Rectangle {
                width: delegateItem.width
                height: rowHeight
                opacity: 0
                visible: isDragging && type === "toggle"
            }

            Icon {
                id: checkmarkIcon
                width: Dims.w(14)
                height: Dims.w(14)
                name: toggleId && toggleEnabled.value[toggleId] ? "ios-checkmark-circle-outline" : "ios-circle-outline"
                color: toggleId && toggleEnabled.value[toggleId] ? "#ffffff" : "#888888"
                visible: {
                    if (type !== "toggle" || toggleId === "" || isDragging) return false;
                    var toggle = findToggle(toggleId);
                    return toggle && toggle.available;
                }
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: Dims.l(15)
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (toggleId) {
                            var newEnabled = Object.assign({}, toggleEnabled.value)
                            var isFixedToggle = fixedToggles.value.indexOf(toggleId) !== -1
                            var isSliderToggle = sliderToggles.value.indexOf(toggleId) !== -1

                            // Count active toggles in fixed row
                            var fixedActiveCount = 0
                            for (var i = 0; i < fixedToggles.value.length; i++) {
                                var fixedId = fixedToggles.value[i]
                                if (fixedId && newEnabled[fixedId]) {
                                    fixedActiveCount++
                                }
                            }

                            // Count active toggles in slider row
                            var sliderActiveCount = 0
                            for (var j = 0; j < sliderToggles.value.length; j++) {
                                var sliderId = sliderToggles.value[j]
                                if (sliderId && newEnabled[sliderId]) {
                                    sliderActiveCount++
                                }
                            }

                            // Prevent disabling if at minimum active toggles
                            if (newEnabled[toggleId]) {
                                if (isFixedToggle && fixedActiveCount <= 1) {
                                    return // Don't disable if only 1 fixed toggle is active
                                }
                                if (isSliderToggle && sliderActiveCount <= 2) {
                                    return // Don't disable if only 2 slider toggles are active
                                }
                            }

                            newEnabled[toggleId] = !newEnabled[toggleId]
                            toggleEnabled.value = newEnabled
                        }
                    }
                }
            }

            Rectangle {
                id: iconRectangle
                width: Dims.w(14)
                height: Dims.w(14)
                radius: width / 2
                color: "#222222"
                opacity: toggleId && toggleEnabled.value[toggleId] ? 0.7 : 0.3
                visible: type === "toggle" && !isDragging
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: checkmarkIcon.right
                    leftMargin: Dims.l(2)
                }

                Icon {
                    id: toggleIcon
                    name: getToggleIcon(toggleId)
                    width: Dims.w(10)
                    height: Dims.w(10)
                    anchors.centerIn: parent
                    color: "#ffffff"
                    opacity: toggleId && toggleEnabled.value[toggleId] ? 1.0 : 0.5
                    visible: toggleId !== ""
                }
            }

            Label {
                text: getToggleName(toggleId)
                color: "#ffffff"
                opacity: toggleId && toggleEnabled.value[toggleId] ? 1.0 : 0.5
                visible: type === "toggle" && !isDragging
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: iconRectangle.right
                    leftMargin: Dims.l(2)
                }
            }

            Timer {
                id: longPressTimer
                interval: 400
                repeat: false
                running: false

                onTriggered: {
                    dragArea.startDrag();
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
                property bool dragging: false

                function startDrag() {
                    if (!dragging && slotList) {
                        try {
                            dragging = true;
                            draggedItemIndex = index;
                            targetIndex = index;
                            storeOriginalData();
                            if (delegateItem && delegateItem.visible) {
                                var mapPos = delegateItem.mapToItem(slotList, 0, 0);
                                if (mapPos) {
                                    dragProxy.x = 0;
                                    dragProxy.y = mapPos.y;
                                    dragProxy.height = rowHeight;
                                    dragProxy.text = getToggleName(toggleId);
                                    dragProxy.icon = getToggleIcon(toggleId);
                                    dragProxy.visible = true;
                                } else {
                                    throw new Error("Invalid mapping position");
                                }
                            } else {
                                throw new Error("Delegate item not available for drag");
                            }
                        } catch (e) {
                            dragging = false;
                            draggedItemIndex = -1;
                            abortDrag();
                        }
                    }
                }

                onPressed: {
                    startPos = Qt.point(mouse.x, mouse.y);
                    pressHighlight.opacity = 0.2;
                    longPressTimer.start();
                }

                onPositionChanged: {
                    if (dragging && slotList) {
                        try {
                            var pos = mapToItem(slotList, mouse.x, mouse.y);
                            if (pos && dragProxy && dragProxy.visible) {
                                dragProxy.y = pos.y - (safeGet(dragProxy, "height", rowHeight) / 2);
                            }
                        } catch (e) {
                            dragging = false;
                            longPressTimer.stop();
                            abortDrag();
                        }
                    } else if (Math.abs(mouse.x - startPos.x) > 10 || Math.abs(mouse.y - startPos.y) > 10) {
                        longPressTimer.stop();
                    }
                }

                onReleased: {
                    longPressTimer.stop();
                    pressHighlight.opacity = 0;
                    if (dragging) {
                        dragging = false;
                        if (targetIndex !== -1 && draggedItemIndex !== targetIndex) {
                            // Check if the target is valid
                            var restrictedIndices = [
                                0, // Fixed row label
                                findSlidingRowIndex(), // Slider row label
                                slotModel.count - 2, // Options label
                                slotModel.count - 1 // Last config item
                            ];
                            var dropBarrierIndex = Math.min(findFirstUnavailableSliderIndex(), slotModel.count - 2);

                            if (restrictedIndices.includes(targetIndex) || targetIndex >= dropBarrierIndex) {
                                // Invalid drop target, restore original order
                                restoreOriginalOrder();
                            } else {
                                // Valid drop target, finalize move
                                finalizeMove();
                            }
                        }
                        draggedItemIndex = -1;
                        targetIndex = -1;
                        dragProxy.visible = false;
                    }
                }

                onCanceled: {
                    longPressTimer.stop();
                    pressHighlight.opacity = 0;
                    if (dragging) {
                        dragging = false;
                        restoreOriginalOrder();
                        draggedItemIndex = -1;
                        targetIndex = -1;
                        dragProxy.visible = false;
                    }
                }
            }
        }

        Rectangle {
            id: dragProxy
            visible: false
            z: 10
            width: slotList ? slotList.width : 0 // Use slotList.width
            height: rowHeight
            color: "#222222"
            opacity: 0.5
            property string text: ""
            property string icon: ""

            Icon {
                id: dragCheckmark
                width: Dims.w(14)
                height: Dims.w(14)
                name: draggedItemIndex >= 0 &&
                    draggedItemIndex < slotModel.count &&
                    slotModel.get(draggedItemIndex) &&
                    slotModel.get(draggedItemIndex).toggleId &&
                    toggleEnabled.value[slotModel.get(draggedItemIndex).toggleId]
                    ? "ios-checkmark-circle-outline" : "ios-circle-outline"
                color: draggedItemIndex >= 0 &&
                    draggedItemIndex < slotModel.count &&
                    slotModel.get(draggedItemIndex) &&
                    slotModel.get(draggedItemIndex).toggleId &&
                    toggleEnabled.value[slotModel.get(draggedItemIndex).toggleId]
                    ? "#ffffff" : "#888888"
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: Dims.l(10)
                }
            }

            Rectangle {
                id: dragIconRect
                width: Dims.w(14)
                height: Dims.w(14)
                radius: width / 2
                color: "#222222"
                opacity: 0.7
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: dragCheckmark.right
                    leftMargin: Dims.l(2)
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
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: dragIconRect.right
                    leftMargin: Dims.l(2)
                }
            }
        }
    }

    PageHeader {
        id: title
        //% "Quick Settings"
        text: qsTrId("id-quicksettings-page")
    }
    // Function to update configuration arrays
    function updateConfiguration() {
        var fixedArray = [];
        var sliderArray = [];
        var usedToggleIds = [];

        // Sync listView values based on current slotModel indices
        for (var i = 0; i < slotModel.count; i++) {
            var item = slotModel.get(i);
            if (item.type === "toggle" && item.toggleId) {
                if (i >= 1 && i <= 2) {
                    slotModel.setProperty(i, "listView", "fixed");
                } else if (i >= findSlidingRowIndex() + 1 && i < slotModel.count - 2) {
                    slotModel.setProperty(i, "listView", "slider");
                }
            }
        }

        // Assign toggles to arrays based on index
        for (i = 0; i < slotModel.count; i++) {
            item = slotModel.get(i);
            if (item.type === "toggle" && item.toggleId && !usedToggleIds.includes(item.toggleId)) {
                if (i >= 1 && i <= 2 && fixedArray.length < fixedRowLength) {
                    fixedArray.push(item.toggleId);
                    usedToggleIds.push(item.toggleId);
                } else if (i >= findSlidingRowIndex() + 1 && i < slotModel.count - 2) {
                    sliderArray.push(item.toggleId);
                    usedToggleIds.push(item.toggleId);
                }
            }
        }

        // Ensure unavailable toggles are included in sliderArray
        var allToggles = ["brightnessToggle", "hapticsToggle", "cinemaToggle", "bluetoothToggle", "wifiToggle", "soundToggle"];
        for (i = 0; i < allToggles.length; i++) {
            var toggleId = allToggles[i];
            var toggle = findToggle(toggleId);
            if (toggle && !toggle.available && !usedToggleIds.includes(toggleId)) {
                sliderArray.push(toggleId);
                usedToggleIds.push(toggleId);
            }
        }

        // Ensure fixedArray has exactly fixedRowLength valid toggles
        if (fixedArray.length < fixedRowLength) {
            var defaults = ["lockButton", "settingsButton"];
            for (var j = fixedArray.length; j < fixedRowLength; j++) {
                var defaultId = defaults[j % defaults.length];
                if (!usedToggleIds.includes(defaultId)) {
                    fixedArray.push(defaultId);
                    usedToggleIds.push(defaultId);
                } else {
                    var altDefault = defaults[(j + 1) % defaults.length];
                    if (!usedToggleIds.includes(altDefault)) {
                        fixedArray.push(altDefault);
                        usedToggleIds.push(altDefault);
                    }
                }
            }
        }

        // Sort sliderArray: available first, unavailable last
        var indexedSliderArray = sliderArray.map((id, index) => ({ id: id, originalIndex: index }));
        indexedSliderArray.sort((a, b) => {
            var toggleA = findToggle(a.id) || { available: true };
            var toggleB = findToggle(b.id) || { available: true };
            if (toggleA.available === toggleB.available) {
                return a.originalIndex - b.originalIndex;
            }
            return toggleA.available ? -1 : 1;
        });
        sliderArray = indexedSliderArray.map(item => item.id);

        // Update ConfigurationValue
        fixedToggles.value = fixedArray.slice(0, fixedRowLength);
        sliderToggles.value = sliderArray.filter(id => id !== "");
    }

    // Function to find Sliding Row index
    function findSlidingRowIndex() {
        for (var i = 0; i < slotModel.count; i++) {
            if (slotModel.get(i).type === "label" && slotModel.get(i).labelText === qsTrId("id-sliding-row")) {
                return i;
            }
        }
        return -1;
    }

    // Function to visually move items during drag
    function moveItems() {
        if (draggedItemIndex === -1 || targetIndex === -1 || draggedItemIndex === targetIndex) {
            return;
        }

        // Prevent moving to restricted indices
        var restrictedIndices = [
            0, // Fixed row label
            findSlidingRowIndex(), // Slider row label
            slotModel.count - 2, // Options label
            slotModel.count - 1 // Last config item
        ];
        var dropBarrierIndex = Math.min(findFirstUnavailableSliderIndex(), slotModel.count - 2);
        if (restrictedIndices.includes(targetIndex) || targetIndex >= dropBarrierIndex) {
            return;
        }

        // Move item in the model
        slotModel.move(draggedItemIndex, targetIndex, 1);

        // Update listView for moved toggle (at targetIndex)
        if (slotModel.get(targetIndex).type === "toggle") {
            if (targetIndex >= 1 && targetIndex <= 2) {
                slotModel.setProperty(targetIndex, "listView", "fixed");
            } else if (targetIndex >= findSlidingRowIndex() + 1 && targetIndex < dropBarrierIndex) {
                slotModel.setProperty(targetIndex, "listView", "slider");
            }
        }

        // Ensure Sliding Row label stays at the correct position
        var slidingRowIndex = findSlidingRowIndex();
        if (slidingRowIndex !== 3) {
            slotModel.move(slidingRowIndex, 3, 1);
        }

        // Update configuration
        updateConfiguration();

        // Update draggedItemIndex to new position
        draggedItemIndex = targetIndex;

        // Store new state as original data
        storeOriginalData();
    }

    // Function to finalize the move
    function finalizeMove() {
        // Ensure Sliding Row label is at index 3
        var slidingRowIndex = findSlidingRowIndex();
        if (slidingRowIndex !== 3) {
            slotModel.move(slidingRowIndex, 3, 1);
        }

        // Update configuration
        updateConfiguration();

        // Validate fixedToggles to prevent duplicates
        var fixedArray = fixedToggles.value.slice();
        var uniqueFixed = [];
        var usedIds = [];
        for (var i = 0; i < fixedArray.length; i++) {
            if (!usedIds.includes(fixedArray[i])) {
                uniqueFixed.push(fixedArray[i]);
                usedIds.push(fixedArray[i]);
            }
        }
        if (uniqueFixed.length < fixedRowLength) {
            var defaults = ["lockButton", "settingsButton"];
            for (i = uniqueFixed.length; i < fixedRowLength; i++) {
                var defaultId = defaults[i % defaults.length];
                if (!usedIds.includes(defaultId)) {
                    uniqueFixed.push(defaultId);
                    usedIds.push(defaultId);
                } else {
                    var altDefault = defaults[(i + 1) % defaults.length];
                    if (!usedIds.includes(altDefault)) {
                        uniqueFixed.push(altDefault);
                        usedIds.push(altDefault);
                    }
                }
            }
        }
        fixedToggles.value = uniqueFixed.slice(0, fixedRowLength);

        // Refresh slotModel to sync with configuration
        slotModel.clear();
        slotModel.append({ type: "label", labelText: qsTrId("id-fixed-row"), toggleId: "", listView: "" });
        for (i = 0; i < fixedToggles.value.length; i++) {
            if (fixedToggles.value[i]) {
                slotModel.append({ type: "toggle", toggleId: fixedToggles.value[i], listView: "fixed", labelText: "" });
            }
        }
        slotModel.append({ type: "label", labelText: qsTrId("id-sliding-row"), toggleId: "", listView: "" });
        for (i = 0; i < sliderToggles.value.length; i++) {
            if (sliderToggles.value[i]) {
                slotModel.append({ type: "toggle", toggleId: sliderToggles.value[i], listView: "slider", labelText: "" });
            }
        }
        slotModel.append({ type: "label", labelText: qsTrId("id-options"), toggleId: "", listView: "" });
        slotModel.append({ type: "config", labelText: qsTrId("id-battery-bottom"), toggleId: "", listView: "" });
        slotModel.append({ type: "config", labelText: qsTrId("id-battery-animation"), toggleId: "", listView: "" });
        slotModel.append({ type: "config", labelText: qsTrId("id-battery-colored"), toggleId: "", listView: "" });

        // Reset drag state
        draggedItemIndex = -1;
        targetIndex = -1;
        dragProxy.visible = false;
        storeOriginalData();
    }

    // Function to restore original order if drag is cancelled
    function restoreOriginalOrder() {
        // Clear the model and repopulate with original data
        slotModel.clear();
        for (var i = 0; i < originalData.length; i++) {
            slotModel.append(originalData[i]);
        }
    }

    function abortDrag() {
        try {
            if (draggedItemIndex !== -1) {
                restoreOriginalOrder();
            }
            draggedItemIndex = -1;
            targetIndex = -1;
            if (dragProxy) {
                dragProxy.visible = false;
            }
            // Reset any other state
            if (scrollTimer && scrollTimer.running) {
                scrollTimer.stop();
            }
        } catch (e) {
            // Last resort reset
            draggedItemIndex = -1;
            targetIndex = -1;
        }
    }

    function safeGet(obj, prop, defaultValue) {
        return (obj && obj[prop] !== undefined) ? obj[prop] : defaultValue;
    }

    // Updated function to find either first unavailable toggle or Options label
    function findFirstUnavailableSliderIndex() {
        var slidingRowIndex = findSlidingRowIndex();
        if (slidingRowIndex === -1) return slotModel.count; // Fallback

        // Find Options label index
        var optionsLabelIndex = -1;
        for (var i = 0; i < slotModel.count; i++) {
            if (slotModel.get(i).type === "label" && slotModel.get(i).labelText === qsTrId("id-options")) {
                optionsLabelIndex = i;
                break;
            }
        }

        // Find first unavailable toggle
        var firstUnavailableIndex = slotModel.count;
        for (i = slidingRowIndex + 1; i < slotModel.count; i++) {
            var item = slotModel.get(i);
            if (item.type === "toggle" && item.listView === "slider") {
                var toggle = findToggle(item.toggleId);
                if (toggle && !toggle.available) {
                    firstUnavailableIndex = i;
                    break;
                }
            }
        }

        // Return the smaller of the two indices (first barrier encountered)
        return Math.min(firstUnavailableIndex, optionsLabelIndex !== -1 ? optionsLabelIndex : slotModel.count);
    }
}
