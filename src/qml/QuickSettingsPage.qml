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
        { id: "lockButton", name: qsTrId("id-toggle-lock"), icon: "ios-unlock", available: true },
        { id: "settingsButton", name: qsTrId("id-toggle-settings"), icon: "ios-settings", available: true },
        { id: "brightnessToggle", name: qsTrId("id-toggle-brightness"), icon: "ios-sunny", available: true },
        { id: "bluetoothToggle", name: qsTrId("id-toggle-bluetooth"), icon: "ios-bluetooth", available: true },
        { id: "hapticsToggle", name: qsTrId("id-toggle-haptics"), icon: "ios-watch-vibrating", available: true },
        { id: "wifiToggle", name: qsTrId("id-toggle-wifi"), icon: "ios-wifi-outline", available: DeviceInfo.hasWlan },
        { id: "soundToggle", name: qsTrId("id-toggle-sound"), icon: "ios-sound-indicator-high", available: DeviceInfo.hasSpeaker },
        { id: "cinemaToggle", name: qsTrId("id-toggle-cinema"), icon: "ios-film-outline", available: true }
    ]

    property real rowHeight: Dims.h(16)
    property real labelHeight: rowHeight * 0.5
    property int draggedItemIndex: -1
    property int targetIndex: -1
    property int fixedRowLength: 2
    property real dragYOffset: 0
    property string draggedToggleId: ""
    property bool crossRowMoveInProgress: false

    function safeGet(obj, prop, defaultValue) {
        return obj && obj[prop] !== undefined ? obj[prop] : defaultValue;
    }

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

    ListModel {
        id: slotModel
        Component.onCompleted: {
            refreshModel();
        }
    }

    function sortToggles(toggleIds) {
        return toggleIds.sort(function(a, b) {
            var toggleA = findToggle(a);
            var toggleB = findToggle(b);

            // First sort by availability (available first)
            if (toggleA && toggleB) {
                if (toggleA.available && !toggleB.available) return -1;
                if (!toggleA.available && toggleB.available) return 1;
            }

            // Then keep original order
            return 0;
        });
    }

    function refreshModel() {
        slotModel.clear();

        // Sort fixed toggles by availability
        var sortedFixedToggles = sortToggles(fixedToggles.value);

        // Sort slider toggles by availability
        var sortedSliderToggles = sortToggles(sliderToggles.value);

        slotModel.append({ type: "label", labelText: qsTrId("id-fixed-row"), toggleId: "", listView: "" });
        for (var i = 0; i < sortedFixedToggles.length && i < fixedRowLength; i++) {
            if (sortedFixedToggles[i]) {
                slotModel.append({
                    type: "toggle",
                    toggleId: sortedFixedToggles[i],
                    listView: "fixed",
                    labelText: ""
                });
            }
        }

        while (countFixedToggles() < fixedRowLength) {
            // Find an available toggle to fill empty slots
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

            // If no available toggles found, try with unavailable ones
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

            // Safety check to prevent infinite loop
            if (countFixedToggles() >= fixedRowLength) break;
        }

        slotModel.append({ type: "label", labelText: qsTrId("id-sliding-row"), toggleId: "", listView: "" });
        for (i = 0; i < sortedSliderToggles.length; i++) {
            if (sortedSliderToggles[i] && !isToggleInFixedRow(sortedSliderToggles[i])) {
                slotModel.append({
                    type: "toggle",
                    toggleId: sortedSliderToggles[i],
                    listView: "slider",
                    labelText: ""
                });
            }
        }

        slotModel.append({ type: "label", labelText: qsTrId("id-options"), toggleId: "", listView: "" });
        slotModel.append({ type: "config", labelText: qsTrId("id-battery-bottom"), toggleId: "", listView: "" });
        slotModel.append({ type: "config", labelText: qsTrId("id-battery-animation"), toggleId: "", listView: "" });
        slotModel.append({ type: "config", labelText: qsTrId("id-battery-colored"), toggleId: "", listView: "" });

        saveConfiguration();
    }

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

    function findSliderLabelIndex() {
        for (var i = 0; i < slotModel.count; i++) {
            if (slotModel.get(i).type === "label" && slotModel.get(i).labelText === qsTrId("id-sliding-row")) {
                return i;
            }
        }
        return 3;
    }

    function findOptionsLabelIndex() {
        for (var i = 0; i < slotModel.count; i++) {
            if (slotModel.get(i).type === "label" && slotModel.get(i).labelText === qsTrId("id-options")) {
                return i;
            }
        }
        return slotModel.count - 4;
    }

    function ensureSliderLabelPosition() {
        var sliderIndex = findSliderLabelIndex();
        if (sliderIndex !== 3) {
            slotModel.move(sliderIndex, 3, 1);
        }
    }

    function isValidDropPosition(dropIndex) {
        // Always prevent dropping on labels and config items
        if (slotModel.get(dropIndex).type !== "toggle") {
            return false;
        }

        var sliderLabelIndex = findSliderLabelIndex();
        var optionsIndex = findOptionsLabelIndex();

        // Prevent dropping below unavailable toggles
        var toggleSection = dropIndex < sliderLabelIndex ? "fixed" : "slider";
        var sectionStart = toggleSection === "fixed" ? 1 : sliderLabelIndex + 1;
        var sectionEnd = toggleSection === "fixed" ? sliderLabelIndex : optionsIndex;

        // Find the first unavailable toggle in this section
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

        // If there's an unavailable toggle in this section and we're trying to drop below it
        if (firstUnavailableIndex !== -1 && dropIndex >= firstUnavailableIndex) {
            return false;
        }

        return true;
    }

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

        // Save the arrays with the current order
        fixedToggles.value = fixedArray;
        sliderToggles.value = sliderArray;
    }

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

        // Lock dragProxy content
        dragProxy.text = getToggleName(draggedToggleId);
        dragProxy.icon = getToggleIcon(draggedToggleId);

        // Handle same-row moves
        if ((draggedItemIndex < sliderLabelIndex && targetIndex < sliderLabelIndex) ||
            (draggedItemIndex > sliderLabelIndex && targetIndex > sliderLabelIndex && targetIndex < optionsLabelIndex)) {
            slotModel.move(draggedItemIndex, targetIndex, 1);
            slotModel.setProperty(targetIndex, "listView", targetIndex < sliderLabelIndex ? "fixed" : "slider");
            draggedItemIndex = targetIndex;
        }
        // Handle slider to fixed move
        else if (draggedItemIndex > sliderLabelIndex && targetIndex < sliderLabelIndex) {
            crossRowMoveInProgress = true;
            var targetToggleId = slotModel.get(targetIndex).toggleId;

            // Use move with animation for both operations
            slotModel.move(draggedItemIndex, targetIndex, 1);
            slotModel.setProperty(targetIndex, "listView", "fixed");

            // Add a slight delay before the second move to let animation start
            moveTimer.targetToggleIndex = targetIndex + 1;
            moveTimer.newPosition = sliderLabelIndex + 1;
            moveTimer.start();

            draggedItemIndex = targetIndex;
        }
        // Handle fixed to slider move
        else if (draggedItemIndex < sliderLabelIndex && targetIndex > sliderLabelIndex && targetIndex < optionsLabelIndex) {
            crossRowMoveInProgress = true;
            var targetToggleId = slotModel.get(targetIndex).toggleId;

            // Use move with animation for both operations
            slotModel.move(draggedItemIndex, targetIndex, 1);
            slotModel.setProperty(targetIndex, "listView", "slider");

            // Add a slight delay before the second move to let animation start
            moveTimer.targetToggleIndex = targetIndex - 1;
            moveTimer.newPosition = draggedItemIndex;
            moveTimer.start();

            draggedItemIndex = targetIndex;
        }

        saveConfiguration();
        slotList.forceLayout();
    }

    function restoreOriginalOrder() {
        if (draggedItemIndex !== -1 && targetIndex !== -1 && draggedItemIndex !== targetIndex) {
            slotModel.move(draggedItemIndex, targetIndex, 1);
            slotModel.setProperty(targetIndex, "listView", targetIndex < findSliderLabelIndex() ? "fixed" : "slider");
            saveConfiguration();
        }
    }

    function abortDrag() {
        if (draggedItemIndex !== -1) {
            restoreOriginalOrder();
        }
        draggedItemIndex = -1;
        targetIndex = -1;
        dragProxy.visible = false;
        autoScrollTimer.scrollSpeed = 0;
    }

    Timer {
        id: moveTimer
        interval: 50  // Short delay to allow animation to start
        repeat: false
        property int targetToggleIndex: -1
        property int newPosition: -1

        onTriggered: {
            if (targetToggleIndex >= 0 && newPosition >= 0) {
                slotModel.move(targetToggleIndex, newPosition, 1);
                slotModel.setProperty(newPosition, "listView", newPosition < findSliderLabelIndex() ? "fixed" : "slider");
                targetToggleIndex = -1;
                newPosition = -1;

                // Ensure slider label stays in place
                ensureSliderLabelPosition();
                saveConfiguration();

                // Reset cross-row flag
                crossRowMoveInProgress = false;
            }
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
        clip: true
        interactive: draggedItemIndex === -1
        model: slotModel
        cacheBuffer: rowHeight * 10
        boundsBehavior: Flickable.OvershootBounds

        header: Item {
            width: parent.width
            height: title.height
        }

        footer: Item {
            width: parent.width
            height: rowHeight * 1.5
        }

        Timer {
            id: autoScrollTimer
            interval: 16
            repeat: true
            running: draggedItemIndex !== -1
            property real scrollSpeed: 0
            property real scrollThreshold: slotList.height * 0.2

            onTriggered: {
                if (draggedItemIndex === -1) {
                    scrollSpeed = 0;
                    running = false;
                    return;
                }
                if (Math.abs(scrollSpeed) > 0.1) {
                    var newContentY = slotList.contentY + scrollSpeed;
                    // Allow contentY to go negative to account for header
                    var minContentY = -title.height;
                    newContentY = Math.max(minContentY, Math.min(newContentY, slotList.contentHeight - slotList.height));
                    slotList.contentY = newContentY;
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

        add: Transition {
            NumberAnimation {
                properties: "y,opacity"
                from: 0
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        move: Transition {
            NumberAnimation {
                properties: "y"
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        delegate: Item {
            id: delegateItem
            width: slotList.width
            height: type === "label" ? labelHeight : type === "config" ? Math.max(rowHeight * 2, childrenRect.height) : rowHeight
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
                // Update opacity to handle both inactive and unavailable states
                opacity: {
                    if (type !== "toggle") return 0;
                    if (toggleId === "") return 0;
                    var toggle = findToggle(toggleId);
                    if (!toggle || !toggle.available) return 0.3; // Unavailable toggle
                    return toggleEnabled.value[toggleId] ? 0.7 : 0.3; // Active vs inactive
                }
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
                    // Update opacity to handle both inactive and unavailable states
                    opacity: {
                        if (toggleId === "") return 0;
                        var toggle = findToggle(toggleId);
                        if (!toggle || !toggle.available) return 0.5; // Unavailable toggle
                        return toggleEnabled.value[toggleId] ? 1.0 : 0.5; // Active vs inactive
                    }
                    visible: toggleId !== ""
                }
            }

            Label {
                text: getToggleName(toggleId)
                color: "#ffffff"
                // Update opacity to handle both inactive and unavailable states
                opacity: {
                    if (toggleId === "") return 0;
                    var toggle = findToggle(toggleId);
                    if (!toggle || !toggle.available) return 0.5; // Unavailable toggle
                    return toggleEnabled.value[toggleId] ? 1.0 : 0.5; // Active vs inactive
                }
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
                onTriggered: {
                    if (type === "toggle") {
                        var toggle = findToggle(toggleId);
                        if (toggle && toggle.available) {
                            draggedItemIndex = index;
                            targetIndex = index;
                            draggedToggleId = toggleId; // Store dragged toggle ID
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

                onPressed: {
                    startPos = Qt.point(mouse.x, mouse.y);
                    longPressTimer.start();
                }

                onPositionChanged: {
                    if (draggedItemIndex !== -1) {
                        var pos = mapToItem(slotList, mouse.x, mouse.y);
                        dragProxy.y = pos.y - dragYOffset;

                        // Adjust scroll calculations to account for header
                        var distFromTop = pos.y;
                        var distFromBottom = slotList.height - pos.y;
                        if (distFromTop < autoScrollTimer.scrollThreshold) {
                            autoScrollTimer.scrollSpeed = -25 * (1 - distFromTop / autoScrollTimer.scrollThreshold);
                        } else if (distFromBottom < autoScrollTimer.scrollThreshold) {
                            autoScrollTimer.scrollSpeed = 25 * (1 - distFromBottom / autoScrollTimer.scrollThreshold);
                        } else {
                            autoScrollTimer.scrollSpeed = 0;
                        }

                        // Account for header when calculating drop position
                        var dropY = pos.y + slotList.contentY;

                        // Only try to get an item if we're below the header
                        if (dropY >= 0) {
                            var itemUnder = slotList.itemAt(slotList.width / 2, dropY);
                            if (itemUnder && itemUnder.visualIndex !== undefined) {
                                var dropIndex = itemUnder.visualIndex;
                                var optionsIndex = findOptionsLabelIndex();

                                // Check if this is a valid drop position
                                if (dropIndex !== draggedItemIndex &&
                                    dropIndex < optionsIndex &&
                                    isValidDropPosition(dropIndex)) {

                                    var targetY = itemUnder.y + itemUnder.height / 2;
                                    if (dropY < targetY && dropIndex > 0) {
                                        var prevItem = slotModel.get(dropIndex - 1);
                                        if (prevItem.type !== "label" && isValidDropPosition(dropIndex - 1)) {
                                            dropIndex -= 1;
                                        }
                                    }

                                    if (dropIndex !== targetIndex) {
                                        targetIndex = dropIndex;
                                        moveItems();
                                    }
                                }
                            }
                        }
                    } else if (Math.abs(mouse.x - startPos.x) > 10 || Math.abs(mouse.y - startPos.y) > 10) {
                        longPressTimer.stop();
                    }
                }

                onReleased: {
                    // Reset highlight first
                    longPressTimer.stop();

                    if (draggedItemIndex !== -1) {
                        var pos = mapToItem(slotList, mouse.x, mouse.y);
                        var dropY = pos.y + slotList.contentY;

                        // Only process drop if we're below the header
                        if (dropY >= 0) {
                            var itemUnder = slotList.itemAt(slotList.width / 2, dropY);
                            if (itemUnder && itemUnder.visualIndex !== undefined) {
                                var dropIndex = itemUnder.visualIndex;
                                var optionsIndex = findOptionsLabelIndex();
                                var sliderLabelIndex = findSliderLabelIndex();

                                // Only allow dropping if it's a valid position
                                if (dropIndex !== draggedItemIndex &&
                                    dropIndex < optionsIndex &&
                                    dropIndex !== sliderLabelIndex &&
                                    isValidDropPosition(dropIndex)) {

                                    targetIndex = dropIndex;
                                    moveItems();
                                }
                            }
                        }

                        // Always end the drag operation
                        dragProxy.visible = false;
                        draggedItemIndex = -1;
                        targetIndex = -1;
                        autoScrollTimer.scrollSpeed = 0;
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

    Item {
        id: dragProxy
        visible: false
        z: 10
        width: slotList.width
        height: rowHeight
        property string text: ""
        property string icon: ""

        HighlightBar {
            anchors.fill: parent
            forceOn: dragProxy.visible
        }

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

    PageHeader {
        id: title
        text: qsTrId("id-quicksettings-page")
    }
}
