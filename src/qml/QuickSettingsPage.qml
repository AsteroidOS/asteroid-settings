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
        defaultValue: ["lockButton", "settingsButton", ""]
    }
    ConfigurationValue {
        id: mainToggles
        key: "/desktop/asteroid/quicksettings/main"
        defaultValue: ["brightnessToggle", "bluetoothToggle", "hapticsToggle", "wifiToggle", "soundToggle", "cinemaToggle"]
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
    property int draggedItemIndex: -1  // The index of the item being dragged
    property int targetIndex: -1       // The target index where item will be dropped
    property int topLength: topToggles.value.length // Number of top slots

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
        //% "empty"
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
            originalData.push({
                toggleId: slotModel.get(i).toggleId,
                listView: slotModel.get(i).listView
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
            // Populate from topToggles
            for (var i = 0; i < topToggles.value.length; i++) {
                append({ toggleId: topToggles.value[i], listView: "top" });
            }
            // Populate from mainToggles
            for (var j = 0; j < mainToggles.value.length; j++) {
                append({ toggleId: mainToggles.value[j], listView: "main" });
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
                                if (newTargetIndex !== targetIndex && newTargetIndex !== -1) {
                                    targetIndex = newTargetIndex;
                                    // Move items in the UI
                                    moveItems();
                                }
                                break;
                            }
                        }
                    }
                }
            }

            // Global function to animate position changes of ListView items
            displaced: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: 120
                    easing.type: Easing.InOutQuad
                }
            }

            delegate: Item {
                id: delegateItem
                width: parent.width
                height: rowHeight
                property int visualIndex: index
                property bool isDragging: index === draggedItemIndex

                // Measure content width dynamically
                Text {
                    id: labelMeasure
                    text: getToggleName(toggleId)
                    font.pixelSize: Dims.l(8)
                    visible: false // Hidden, used for sizing
                }

                Rectangle {
                    id: slotRect
                    height: rowHeight - Dims.l(2)
                    width: Dims.w(14) + (Dims.w(8) * 2) + labelMeasure.width // icon + doubled padding + label
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#222222"
                    opacity: 0.4 // Only background
                    radius: height / 2 // Pill-shaped
                    visible: !isDragging
                }

                // Content above background
                Row {
                    anchors.centerIn: slotRect
                    spacing: Dims.w(2)

                    Rectangle {
                        width: Dims.w(14)
                        height: Dims.w(14)
                        radius: width / 2
                        color: "#222222"
                        opacity: 0.7 // Toggled QuickSettingsToggle alpha

                        Icon {
                            id: toggleIcon
                            name: getToggleIcon(toggleId)
                            width: Dims.w(10)
                            height: Dims.w(10)
                            anchors.centerIn: parent
                            color: "#ffffff"
                            visible: toggleId !== ""
                        }
                    }

                    Label {
                        text: getToggleName(toggleId)
                        font.pixelSize: Dims.l(8)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Timer {
                    id: longPressTimer
                    interval: 400  // Hold for 400ms to start dragging
                    repeat: false
                    running: false

                    onTriggered: {
                        // Start drag after the timer expires
                        dragArea.startDrag();
                    }
                }

                MouseArea {
                    id: dragArea
                    anchors.fill: parent

                    property point startPos: Qt.point(0, 0)
                    property bool dragging: false

                    function startDrag() {
                        if (!dragging) {
                            dragging = true;
                            draggedItemIndex = index;
                            targetIndex = index;

                            // Store original item positions for potential restoration
                            storeOriginalData();

                            // Position the drag proxy
                            dragProxy.x = slotRect.x;
                            dragProxy.y = delegateItem.mapToItem(slotList, 0, 0).y;
                            dragProxy.width = slotRect.width;
                            dragProxy.height = slotRect.height;
                            dragProxy.text = getToggleName(toggleId);
                            dragProxy.icon = getToggleIcon(toggleId);
                            dragProxy.visible = true;
                        }
                    }

                    onPressed: {
                        startPos = Qt.point(mouse.x, mouse.y);
                        longPressTimer.start();
                    }

                    onPositionChanged: {
                        if (dragging) {
                            // Update position of drag proxy
                            var pos = mapToItem(slotList, mouse.x, mouse.y);
                            dragProxy.y = pos.y - dragProxy.height/2;
                        } else if (Math.abs(mouse.x - startPos.x) > 10 || Math.abs(mouse.y - startPos.y) > 10) {
                            // If moved significantly without starting drag, cancel the long press timer
                            longPressTimer.stop();
                        }
                    }

                    onReleased: {
                        longPressTimer.stop();

                        if (dragging) {
                            dragging = false;

                            // Finalize the move and update configuration
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
                        if (dragging) {
                            dragging = false;
                            dragProxy.visible = false;

                            // Restore the original positions
                            restoreOriginalOrder();

                            draggedItemIndex = -1;
                            targetIndex = -1;
                        }
                    }
                }
            }

            // Drag visual proxy (follows the finger)
            Rectangle {
                id: dragProxy
                visible: false
                z: 10
                color: "#AA222222"
                border.width: Dims.l(1)
                border.color: "#222222"
                radius: height / 2
                height: rowHeight
                property string text: ""
                property string icon: ""

                Row {
                    anchors.centerIn: parent
                    spacing: Dims.w(2)

                    Rectangle {
                        width: Dims.w(14)
                        height: Dims.w(14)
                        radius: width / 2
                        color: "#222222"

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
                        font.pixelSize: Dims.l(8)
                        color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
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
            if (i < topLength) {
                topArray.push(item.toggleId);
            } else {
                mainArray.push(item.toggleId);
            }
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
            var id = mainArray[i];
            if (id && mainArray.indexOf(id, i + 1) !== -1) {
                mainArray[mainArray.indexOf(id, i + 1)] = "";
            }
        }
        // Update ConfigurationValue
        topToggles.value = topArray;
        mainToggles.value = mainArray;
    }

    // Function to visually move items during drag
    function moveItems() {
        if (draggedItemIndex === -1 || targetIndex === -1 || draggedItemIndex === targetIndex) {
            return;
        }

        // Move item in the model
        slotModel.move(draggedItemIndex, targetIndex, 1);

        // Update configuration
        updateConfiguration();

        // Update draggedItemIndex to new position
        draggedItemIndex = targetIndex;

        // Store new state as original data
        storeOriginalData();
    }

    // Function to finalize the move
    function finalizeMove() {
        // No additional storage needed; moveItems handles it
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
