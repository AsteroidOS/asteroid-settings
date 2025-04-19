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

    function refreshModel() {
        slotModel.clear();
        slotModel.append({ type: "label", labelText: qsTrId("id-fixed-row"), toggleId: "", listView: "" });
        for (var i = 0; i < fixedToggles.value.length && i < fixedRowLength; i++) {
            if (fixedToggles.value[i]) {
                slotModel.append({
                    type: "toggle",
                    toggleId: fixedToggles.value[i],
                    listView: "fixed",
                    labelText: ""
                });
            }
        }
        while (countFixedToggles() < fixedRowLength) {
            var defaultId = "lockButton";
            if (!isToggleInFixedRow(defaultId)) {
                slotModel.append({
                    type: "toggle",
                    toggleId: defaultId,
                    listView: "fixed",
                    labelText: ""
                });
            } else if (!isToggleInFixedRow("settingsButton")) {
                slotModel.append({
                    type: "toggle",
                    toggleId: "settingsButton",
                    listView: "fixed",
                    labelText: ""
                });
            } else {
                for (var t = 0; t < toggleOptions.length; t++) {
                    if (toggleOptions[t].available && !isToggleInFixedRow(toggleOptions[t].id)) {
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
        }
        slotModel.append({ type: "label", labelText: qsTrId("id-sliding-row"), toggleId: "", listView: "" });
        for (i = 0; i < sliderToggles.value.length; i++) {
            if (sliderToggles.value[i] && !isToggleInFixedRow(sliderToggles.value[i])) {
                slotModel.append({
                    type: "toggle",
                    toggleId: sliderToggles.value[i],
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

    function moveItems() {
        if (draggedItemIndex === -1 || targetIndex === -1 || draggedItemIndex === targetIndex) {
            return;
        }
        var sliderLabelIndex = findSliderLabelIndex();
        var optionsLabelIndex = findOptionsLabelIndex();
        if (targetIndex === 0 || targetIndex === sliderLabelIndex ||
            targetIndex >= optionsLabelIndex) {
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
            var targetToggleId = slotModel.get(targetIndex).toggleId;
            // Move dragged toggle to target index
            slotModel.move(draggedItemIndex, targetIndex, 1);
            slotModel.setProperty(targetIndex, "listView", "fixed");
            // Move displaced toggle to slider row
            slotModel.move(targetIndex + 1, sliderLabelIndex + 1, 1);
            slotModel.setProperty(sliderLabelIndex + 1, "listView", "slider");
            draggedItemIndex = targetIndex;
        }
        // Handle fixed to slider move
        else if (draggedItemIndex < sliderLabelIndex && targetIndex > sliderLabelIndex && targetIndex < optionsLabelIndex) {
            var targetToggleId = slotModel.get(targetIndex).toggleId;
            // Move dragged toggle to target index
            slotModel.move(draggedItemIndex, targetIndex, 1);
            slotModel.setProperty(targetIndex, "listView", "slider");
            // Move displaced toggle to fixed row
            slotModel.move(targetIndex - 1, draggedItemIndex, 1);
            slotModel.setProperty(draggedItemIndex, "listView", "fixed");
            draggedItemIndex = targetIndex;
        }

        ensureSliderLabelPosition();
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
                    newContentY = Math.max(0, Math.min(newContentY, slotList.contentHeight - slotList.height));
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

        delegate: Item {
            id: delegateItem
            width: slotList.width
            height: type === "label" ? labelHeight : type === "config" ? Math.max(rowHeight * 2, childrenRect.height) : rowHeight
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
                    pressHighlight.opacity = 0.2;
                    longPressTimer.start();
                }

                onPositionChanged: {
                    if (draggedItemIndex !== -1) {
                        var pos = mapToItem(slotList, mouse.x, mouse.y);
                        dragProxy.y = pos.y - dragYOffset;
                        var distFromTop = pos.y;
                        var distFromBottom = slotList.height - pos.y;
                        if (distFromTop < autoScrollTimer.scrollThreshold) {
                            autoScrollTimer.scrollSpeed = -15 * (1 - distFromTop / autoScrollTimer.scrollThreshold);
                        } else if (distFromBottom < autoScrollTimer.scrollThreshold) {
                            autoScrollTimer.scrollSpeed = 15 * (1 - distFromBottom / autoScrollTimer.scrollThreshold);
                        } else {
                            autoScrollTimer.scrollSpeed = 0;
                        }
                        var dropY = pos.y + slotList.contentY;
                        var itemUnder = slotList.itemAt(slotList.width / 2, dropY);
                        if (itemUnder && itemUnder.visualIndex !== undefined) {
                            var dropIndex = itemUnder.visualIndex;
                            var optionsIndex = findOptionsLabelIndex();
                            if (slotModel.get(dropIndex).type !== "label" &&
                                slotModel.get(dropIndex).type !== "config" &&
                                dropIndex !== draggedItemIndex &&
                                dropIndex < optionsIndex) {
                                var targetY = itemUnder.y + itemUnder.height / 2;
                                if (dropY < targetY && dropIndex > 0) {
                                    var prevItem = slotModel.get(dropIndex - 1);
                                    if (prevItem.type !== "label") {
                                        dropIndex -= 1;
                                    }
                                }
                                if (dropIndex !== targetIndex) {
                                    targetIndex = dropIndex;
                                    moveItems();
                                }
                            }
                        }
                    } else if (Math.abs(mouse.x - startPos.x) > 10 || Math.abs(mouse.y - startPos.y) > 10) {
                        longPressTimer.stop();
                    }
                }

                onReleased: {
                    if (draggedItemIndex !== -1) {
                        var pos = mapToItem(slotList, mouse.x, mouse.y);
                        var dropY = pos.y + slotList.contentY;
                        var itemUnder = slotList.itemAt(slotList.width / 2, dropY);
                        if (itemUnder && itemUnder.visualIndex !== undefined) {
                            var dropIndex = itemUnder.visualIndex;
                            var optionsIndex = findOptionsLabelIndex();
                            var sliderLabelIndex = findSliderLabelIndex();
                            if (slotModel.get(dropIndex).type !== "label" &&
                                slotModel.get(dropIndex).type !== "config" &&
                                dropIndex !== draggedItemIndex &&
                                dropIndex < optionsIndex &&
                                dropIndex !== sliderLabelIndex) {
                                targetIndex = dropIndex;
                                moveItems();
                                dragProxy.visible = false;
                                draggedItemIndex = -1;
                                targetIndex = -1;
                            } else {
                                abortDrag();
                            }
                        } else {
                            abortDrag();
                        }
                    }
                }

                onCanceled: {
                    longPressTimer.stop();
                    pressHighlight.opacity = 0;
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

        Rectangle {
            anchors.fill: parent
            color: "#222222"
            opacity: 0.5
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
