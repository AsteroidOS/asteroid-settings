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
        { id: "lockButton", name: qsTrId("id-toggle-lock"), icon: "ios-unlock" },
        //% "Settings Link"
        { id: "settingsButton", name: qsTrId("id-toggle-settings"), icon: "ios-settings" },
        //% "Brightness"
        { id: "brightnessToggle", name: qsTrId("id-toggle-brightness"), icon: "ios-sunny" },
        //% "Bluetooth"
        { id: "bluetoothToggle", name: qsTrId("id-toggle-bluetooth"), icon: "ios-bluetooth" },
        //% "Vibration"
        { id: "hapticsToggle", name: qsTrId("id-toggle-haptics"), icon: "ios-watch-vibrating" },
        //% "WiFi"
        { id: "wifiToggle", name: qsTrId("id-toggle-wifi"), icon: "ios-wifi-outline" },
        //% "Mute Sound"
        { id: "soundToggle", name: qsTrId("id-toggle-sound"), icon: "ios-sound-indicator-high" },
        //% "Cinema Mode"
        { id: "cinemaToggle", name: qsTrId("id-toggle-cinema"), icon: "ios-film-outline" }
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
            // Validate and reset fixedToggles
            var validFixed = fixedToggles.value && Array.isArray(fixedToggles.value) && fixedToggles.value.length >= fixedRowLength;
            if (!validFixed) {
                fixedToggles.value = ["lockButton", "settingsButton"];
            } else {
                // Filter invalid or empty IDs and ensure exactly fixedRowLength valid toggles
                var filteredFixed = fixedToggles.value.filter(id => findToggle(id) && id !== "");
                if (filteredFixed.length < fixedRowLength) {
                    // Fill with defaults if not enough valid toggles
                    var defaults = ["lockButton", "settingsButton"];
                    for (var i = filteredFixed.length; i < fixedRowLength; i++) {
                        filteredFixed.push(defaults[i]);
                    }
                }
                fixedToggles.value = filteredFixed.slice(0, fixedRowLength);
            }

            // Validate and reset sliderToggles
            var validSlider = sliderToggles.value && Array.isArray(sliderToggles.value) && sliderToggles.value.length > 0;
            if (!validSlider) {
                sliderToggles.value = ["brightnessToggle", "bluetoothToggle", "hapticsToggle", "wifiToggle", "soundToggle", "cinemaToggle"];
            } else {
                // Filter invalid or empty IDs
                var filteredSlider = sliderToggles.value.filter(id => findToggle(id) && id !== "");
                if (filteredSlider.length === 0) {
                    filteredSlider = sliderToggles.defaultValue;
                }
                sliderToggles.value = filteredSlider;
            }

            // Validate and reset toggleEnabled
            var validEnabled = toggleEnabled.value && typeof toggleEnabled.value === "object";
            if (!validEnabled) {
                toggleEnabled.value = toggleEnabled.defaultValue;
            } else {
                var newEnabled = Object.assign({}, toggleEnabled.defaultValue);
                for (var id in newEnabled) {
                    if (toggleEnabled.value.hasOwnProperty(id)) {
                        newEnabled[id] = toggleEnabled.value[id];
                    }
                }
                toggleEnabled.value = newEnabled;
            }

            // Validate options
            var validOptions = options.value && typeof options.value === "object";
            if (!validOptions) {
                options.value = options.defaultValue;
            } else {
                var newOptions = Object.assign({}, options.defaultValue);
                for (var opt in newOptions) {
                    if (options.value.hasOwnProperty(opt)) {
                        newOptions[opt] = options.value[opt];
                    }
                }
                options.value = newOptions;
            }

            // Populate model
            //% "Fixed Row Content"
            append({ type: "label", labelText: qsTrId("id-fixed-row"), toggleId: "", listView: "" });
            for (var i = 0; i < fixedToggles.value.length; i++) {
                if (fixedToggles.value[i]) {
                    append({ type: "toggle", toggleId: fixedToggles.value[i], listView: "fixed", labelText: "" });
                }
            }
            //% "Sliding Row Content"
            append({ type: "label", labelText: qsTrId("id-sliding-row"), toggleId: "", listView: "" });
            for (var j = 0; j < sliderToggles.value.length; j++) {
                if (sliderToggles.value[j]) {
                    append({ type: "toggle", toggleId: sliderToggles.value[j], listView: "slider", labelText: "" });
                }
            }
            //% "Options"
            append({ type: "label", labelText: qsTrId("id-options"), toggleId: "", listView: "" });
            //% "Battery aligned to bottom?"
            append({ type: "config", labelText: qsTrId("id-battery-bottom"), toggleId: "", listView: "" });
            //% "Show battery charge animation?"
            append({ type: "config", labelText: qsTrId("id-battery-animation"), toggleId: "", listView: "" });
            //% "Enable colored battery?"
            append({ type: "config", labelText: qsTrId("id-battery-colored"), toggleId: "", listView: "" });
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
                        if (newTargetIndex === 0 || newTargetIndex === 3 ||
                            newTargetIndex === slotModel.count - 2 || newTargetIndex === slotModel.count - 1) {
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
            width: slotList ? slotList.width : 0 // Use slotList.width instead of parent.width
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
                height: Math.max(rowHeight * 2, implicitHeight) // Adjust height based on text content
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
                visible: type === "toggle" && toggleId !== "" && !isDragging
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: Dims.l(15)
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (toggleId) {
                            var newEnabled = Object.assign({}, toggleEnabled.value);
                            newEnabled[toggleId] = !newEnabled[toggleId];
                            toggleEnabled.value = newEnabled;
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
                enabled: !isDragging && type === "toggle"

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
                            finalizeMove();
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
        for (var i = 0; i < slotModel.count - 2; i++) { // Skip spacer and config
            var item = slotModel.get(i);
            if (item.type === "toggle" && item.toggleId) {
                if (i >= 1 && i <= 2) {
                    fixedArray.push(item.toggleId);
                } else if (i >= 4) {
                    sliderArray.push(item.toggleId);
                }
            }
        }
        // Ensure fixedArray has exactly fixedRowLength valid toggles
        if (fixedArray.length < fixedRowLength) {
            var defaults = ["lockButton", "settingsButton"];
            for (var j = fixedArray.length; j < fixedRowLength; j++) {
                fixedArray.push(defaults[j]);
            }
        }
        // Clear duplicates in fixedArray
        for (i = 0; i < fixedArray.length; i++) {
            var id = fixedArray[i];
            if (id && fixedArray.indexOf(id, i + 1) !== -1) {
                fixedArray[fixedArray.indexOf(id, i + 1)] = defaults[i];
            }
        }
        // Clear duplicates in sliderArray
        for (i = 0; i < sliderArray.length; i++) {
            id = sliderArray[i];
            if (id && sliderArray.indexOf(id, i + 1) !== -1) {
                sliderArray[sliderArray.indexOf(id, i + 1)] = "";
            }
        }
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

        // Move item in the model
        slotModel.move(draggedItemIndex, targetIndex, 1);

        // Check and adjust Sliding Row position
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
        // Ensure Sliding Row is at index 3
        var slidingRowIndex = findSlidingRowIndex();
        if (slidingRowIndex !== 3) {
            slotModel.move(slidingRowIndex, 3, 1);
            updateConfiguration();
            storeOriginalData();
        }
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
}
