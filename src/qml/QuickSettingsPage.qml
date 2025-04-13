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

    // ConfigurationValue for slots
    ConfigurationValue { id: topSlot1; key: "/desktop/asteroid/quicksettings/top/slot1"; defaultValue: "lockButton" }
    ConfigurationValue { id: topSlot2; key: "/desktop/asteroid/quicksettings/top/slot2"; defaultValue: "settingsButton" }
    ConfigurationValue { id: topSlot3; key: "/desktop/asteroid/quicksettings/top/slot3"; defaultValue: "" }
    ConfigurationValue { id: mainSlot1; key: "/desktop/asteroid/quicksettings/main/slot1"; defaultValue: "brightnessToggle" }
    ConfigurationValue { id: mainSlot2; key: "/desktop/asteroid/quicksettings/main/slot2"; defaultValue: "bluetoothToggle" }
    ConfigurationValue { id: mainSlot3; key: "/desktop/asteroid/quicksettings/main/slot3"; defaultValue: "hapticsToggle" }
    ConfigurationValue { id: mainSlot4; key: "/desktop/asteroid/quicksettings/main/slot4"; defaultValue: "wifiToggle" }
    ConfigurationValue { id: mainSlot5; key: "/desktop/asteroid/quicksettings/main/slot5"; defaultValue: "soundToggle" }
    ConfigurationValue { id: mainSlot6; key: "/desktop/asteroid/quicksettings/main/slot6"; defaultValue: "cinemaToggle" }

    // Toggle definitions
    property var toggleOptions: [
        { id: "lockButton", name: qsTrId("id-toggle-lock"), icon: "ios-unlock" },
        { id: "settingsButton", name: qsTrId("id-toggle-settings"), icon: "ios-settings" },
        { id: "brightnessToggle", name: qsTrId("id-toggle-brightness"), icon: "ios-sunny" },
        { id: "bluetoothToggle", name: qsTrId("id-toggle-bluetooth"), icon: "ios-bluetooth" },
        { id: "hapticsToggle", name: qsTrId("id-toggle-haptics"), icon: "ios-watch-vibrating" },
        { id: "wifiToggle", name: qsTrId("id-toggle-wifi"), icon: "ios-wifi-outline" },
        { id: "soundToggle", name: qsTrId("id-toggle-sound"), icon: "ios-sound-indicator-high" },
        { id: "cinemaToggle", name: qsTrId("id-toggle-cinema"), icon: "ios-film-outline" }
    ]

    property string rowHeight: Dims.h(14)

    PageHeader {
        id: title
        //% "Quick Settings Order"
        text: qsTrId("id-quicksettings-order")
    }

    Column {
        anchors.fill: parent
        spacing: Dims.h(2)

        Item { width: parent.width; height: Dims.l(25) }

        // Available Toggles Pool
        Label {
            //% "Available Toggles"
            text: qsTrId("id-available-toggles")
            font.pixelSize: Dims.l(6)
            anchors.horizontalCenter: parent.horizontalCenter
        }

        ListView {
            id: togglePool
            width: parent.width
            height: Dims.h(14)
            orientation: ListView.Horizontal
            spacing: Dims.w(2)
            model: toggleOptions

            delegate: Item {
                id: dragItem
                width: Dims.w(14)
                height: Dims.h(14)

                Icon {
                    id: toggleIcon
                    name: modelData.icon
                    width: Dims.w(10)
                    height: Dims.h(10)
                    anchors.centerIn: parent
                    opacity: dragArea.drag.active ? 0.5 : 1.0
                }

                Drag.active: dragArea.drag.active
                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2
                Drag.mimeData: { "toggleId": modelData.id }

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    drag.target: dragItem
                    onReleased: dragItem.Drag.drop()
                }
            }
        }

        // Top Bar Section
        Label {
            //% "Top Bar Toggles"
            text: qsTrId("id-top-bar-toggles")
            font.pixelSize: Dims.l(6)
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Repeater {
            model: [topSlot1, topSlot2, topSlot3]
            delegate: Item {
                width: parent.width
                height: rowHeight

                Rectangle {
                    id: slotRect
                    width: parent.width - Dims.w(10)
                    height: Dims.h(10)
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: dropArea.containsDrag ? "#333333" : "#222222"
                    radius: Dims.w(2)

                    Label {
                        text: {
                            var toggle = toggleOptions.find(function(t) { return t.id === modelData.value; });
                            return toggle ? toggle.name : qsTrId("id-empty-slot");
                        }
                        font.pixelSize: Dims.l(5)
                        anchors.centerIn: parent
                        color: "#ffffff"
                    }

                    DropArea {
                        id: dropArea
                        anchors.fill: parent
                        onDropped: {
                            var toggleId = drop.data["toggleId"];
                            updateSlot("top", index, toggleId);
                        }
                    }
                }
            }
        }

        // Main Settings Section
        Label {
            //% "Main Settings Toggles"
            text: qsTrId("id-main-settings-toggles")
            font.pixelSize: Dims.l(6)
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Repeater {
            model: [mainSlot1, mainSlot2, mainSlot3, mainSlot4, mainSlot5, mainSlot6]
            delegate: Item {
                width: parent.width
                height: rowHeight

                Rectangle {
                    id: slotRect
                    width: parent.width - Dims.w(10)
                    height: Dims.h(10)
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: dropArea.containsDrag ? "#333333" : "#222222"
                    radius: Dims.w(2)

                    Label {
                        text: {
                            var toggle = toggleOptions.find(function(t) { return t.id === modelData.value; });
                            return toggle ? toggle.name : qsTrId("id-empty-slot");
                        }
                        font.pixelSize: Dims.l(5)
                        anchors.centerIn: parent
                        color: "#ffffff"
                    }

                    DropArea {
                        id: dropArea
                        anchors.fill: parent
                        onDropped: {
                            var toggleId = drop.data["toggleId"];
                            updateSlot("main", index, toggleId);
                        }
                    }
                }
            }
        }
    }

    function updateSlot(listView, slotIndex, toggleId) {
        var topSlots = [topSlot1, topSlot2, topSlot3];
        var mainSlots = [mainSlot1, mainSlot2, mainSlot3, mainSlot4, mainSlot5, mainSlot6];
        var targetSlots = listView === "top" ? topSlots : mainSlots;

        // Clear other slots in this ListView if toggleId is assigned
        for (var i = 0; i < targetSlots.length; i++) {
            if (i !== slotIndex && targetSlots[i].value === toggleId) {
                targetSlots[i].value = "";
            }
        }
        targetSlots[slotIndex].value = toggleId;
    }
}
