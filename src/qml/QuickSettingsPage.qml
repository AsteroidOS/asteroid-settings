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
        id: topToggles
        key: "/desktop/asteroid/quicksettings/top"
        defaultValue: ["lockButton", "settingsButton"]
    }
    ConfigurationValue {
        id: mainToggles
        key: "/desktop/asteroid/quicksettings/main"
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

    // Toggle definitions
    property var toggleOptions: [
        //% "Lock Button"
        { id: "lockButton", name: qsTrId("id-toggle-lock"), icon: "ios-unlock" },
        //% "Settings Shortcut"
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
    property int topLength: 2 // Fixed to two top slots

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
        return toggle ? toggle.name : qsTrId("id-empty-slot");
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
                labelText: item.type === "label" ? item.labelText : ""
            });
        }
    }

    PageHeader {
        id: title
        //% "Quick Settings"
        text: qsTrId("id-quicksettings-page")
    }

    ListModel {
        id: slotModel
        Component.onCompleted: {
            // Validate and reset topToggles
            var validTop = topToggles.value && Array.isArray(topToggles.value) && topToggles.value.length > 0;
            if (!validTop) {
                topToggles.value = ["lockButton", "settingsButton"];
            } else {
                // Filter invalid IDs
                var filteredTop = topToggles.value.filter(id => findToggle(id));
                while (filteredTop.length < topLength) {
                    filteredTop.push("");
                }
                topToggles.value = filteredTop.slice(0, topLength);
            }

            // Validate and reset mainToggles
            var validMain = mainToggles.value && Array.isArray(mainToggles.value) && mainToggles.value.length > 0;
            if (!validMain) {
                mainToggles.value = ["brightnessToggle", "bluetoothToggle", "hapticsToggle", "wifiToggle", "soundToggle", "cinemaToggle"];
            } else {
                // Filter invalid IDs
                var filteredMain = mainToggles.value.filter(id => findToggle(id));
                if (filteredMain.length === 0) {
                    filteredMain = mainToggles.defaultValue;
                }
                mainToggles.value = filteredMain;
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

            // Populate model
            //% "Fixed Row"
            append({ type: "label", labelText: qsTrId("id-fixed-row"), toggleId: "", listView: "" });
            for (var i = 0; i < topToggles.value.length; i++) {
                append({ type: "toggle", toggleId: topToggles.value[i], listView: "top", labelText: "" });
            }
            //% "Sliding Row"
            append({ type: "label", labelText: qsTrId("id-sliding-row"), toggleId: "", listView: "" });
            for (var j = 0; j < mainToggles.value.length; j++) {
                append({ type: "toggle", toggleId: mainToggles.value[j], listView: "main", labelText: "" });
            }
            storeOriginalData();
        }
    }

    Column {
        anchors.fill: parent

        Item { width: parent.width; height: Dims.l(20) }

        ListView {
            id: slotList
            width: parent.width
            anchors {
                top: parent.top
                topMargin: Dims.l(20)
                bottom: parent.bottom
            }
            clip: true
            interactive: draggedItemIndex === -1 // Only allow scrolling when not dragging
            model: slotModel

            // Auto-scroll when dragging near edges
            Timer {
                id: scrollTimer
                interval: 16
                repeat: true
                running: draggedItemIndex !== -1

                onTriggered: {
                    if (dragProxy.y < slotList.height * 0.2) {
                        // Scroll up
                        slotList.contentY = Math.max(0, slotList.contentY - 5);
                    } else if (dragProxy.y > slotList.height * 0.8) {
                        // Scroll down
                        slotList.contentY = Math.min(
                            slotList.contentHeight - slotList.height,
                            slotList.contentY + 5
                        );
                    }

                    // Continuously check which item is under the drag proxy
                    if (draggedItemIndex !== -1) {
                        var dragCenterY = dragProxy.y + dragProxy.height / 2;
                        for (var i = 0; i < slotList.count; i++) {
                            var item = slotList.itemAt(0, slotList.contentY + dragCenterY);
                            if (item) {
                                var newTargetIndex = item.visualIndex;
                                // Prevent dropping at index 0 (Fixed Row) or 3 (Sliding Row)
                                if (newTargetIndex === 0 || newTargetIndex === 3) {
                                    continue;
                                }
                                if (newTargetIndex !== targetIndex && newTargetIndex !== -1) {
                                    targetIndex = newTargetIndex;
                                    moveItems();
                                }
                                break;
                            }
                        }
                    }
                }
            }

            // Animation for displaced items
            displaced: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }

            delegate: Item {
                id: delegateItem
                width: parent.width
                height: type === "label" ? labelHeight : rowHeight
                property int visualIndex: index
                property bool isDragging: index === draggedItemIndex

                // Fake press highlight
                Rectangle {
                    id: pressHighlight
                    width: parent.width
                    height: rowHeight
                    color: "#222222"
                    opacity: 0
                    visible: type === "toggle"
                    z: -1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                // Label delegate
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

                // Toggle delegate
                Rectangle {
                    width: parent.width
                    height: rowHeight
                    opacity: 0
                    visible: isDragging && type === "toggle"
                }

                // Checkmark
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
                        leftMargin: Dims.l(10)
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

                // Icon
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

                // Label
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
                    enabled: !isDragging && type === "toggle" // Disable for labels

                    property point startPos: Qt.point(0, 0)
                    property bool dragging: false

                    function startDrag() {
                        if (!dragging) {
                            dragging = true;
                            draggedItemIndex = index;
                            targetIndex = index;

                            storeOriginalData();

                            dragProxy.x = 0;
                            dragProxy.y = delegateItem.mapToItem(slotList, 0, 0).y;
                            dragProxy.height = rowHeight;
                            dragProxy.text = getToggleName(toggleId);
                            dragProxy.icon = getToggleIcon(toggleId);
                            dragProxy.visible = true;
                        }
                    }

                    onPressed: {
                        startPos = Qt.point(mouse.x, mouse.y);
                        pressHighlight.opacity = 0.2;
                        longPressTimer.start();
                    }

                    onPositionChanged: {
                        if (dragging) {
                            var pos = mapToItem(slotList, mouse.x, mouse.y);
                            dragProxy.y = pos.y - dragProxy.height/2;
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

                            dragProxy.visible = false;
                            draggedItemIndex = -1;
                            targetIndex = -1;
                        }
                    }

                    onCanceled: {
                        longPressTimer.stop();
                        pressHighlight.opacity = 0;
                        if (dragging) {
                            dragging = false;
                            dragProxy.visible = false;

                            restoreOriginalOrder();

                            draggedItemIndex = -1;
                            targetIndex = -1;
                        }
                    }
                }
            }

            // Drag visual proxy
            Rectangle {
                id: dragProxy
                visible: false
                z: 10
                width: parent.width
                height: rowHeight
                color: "#222222"
                opacity: 0.5
                property string text: ""
                property string icon: ""

                Icon {
                    id: dragCheckmark
                    width: Dims.w(14)
                    height: Dims.w(14)
                    name: dragProxy.text === qsTrId("id-empty-slot") ? "ios-circle-outline" : (toggleEnabled.value[slotModel.get(draggedItemIndex).toggleId] ? "ios-checkmark-circle-outline" : "ios-circle-outline")
                    color: dragProxy.text === qsTrId("id-empty-slot") ? "#888888" : (toggleEnabled.value[slotModel.get(draggedItemIndex).toggleId] ? "#ffffff" : "#888888")
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
    }

    // Function to update configuration arrays
    function updateConfiguration() {
        var topArray = [];
        var mainArray = [];
        for (var i = 0; i < slotModel.count; i++) {
            var item = slotModel.get(i);
            if (item.type === "toggle") {
                if (i >= 1 && i <= 2) {
                    topArray.push(item.toggleId);
                } else if (i >= 4) {
                    mainArray.push(item.toggleId);
                }
            }
        }
        // Pad topArray if needed
        while (topArray.length < topLength) {
            topArray.push("");
        }
        // Clear duplicates in top
        for (i = 0; i < topArray.length; i++) {
            var id = topArray[i];
            if (id && topArray.indexOf(id, i + 1) !== -1) {
                topArray[topArray.indexOf(id, i + 1)] = "";
            }
        }
        // Clear duplicates in main
        for (i = 0; i < mainArray.length; i++) {
            id = mainArray[i];
            if (id && mainArray.indexOf(id, i + 1) !== -1) {
                mainArray[mainArray.indexOf(id, i + 1)] = "";
            }
        }
        // Update ConfigurationValue
        topToggles.value = topArray;
        mainToggles.value = mainArray;
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
}
