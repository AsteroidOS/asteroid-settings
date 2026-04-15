/*
 * Copyright (C) 2024 - AsteroidOS Contributors
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
import Nemo.DBus 2.0

Item {
    id: root

    property string profileId: ""
    property bool isNewProfile: false
    property var profile: ({})

    property var sensorModeLabels: ({
        "off": qsTrId("id-off"),
        "low": qsTrId("id-low"),
        "medium": qsTrId("id-medium"),
        "high": qsTrId("id-high"),
        "workout": qsTrId("id-workout"),
        "sleep_only": qsTrId("id-sleep-only"),
        "always": qsTrId("id-always"),
        "periodic": qsTrId("id-periodic"),
        "continuous": qsTrId("id-continuous"),
        "on_demand": qsTrId("id-on-demand")
    })

    DBusInterface {
        id: powerd
        bus: DBus.SystemBus
        service: "org.asteroidos.powerd"
        path: "/org/asteroidos/powerd"
        iface: "org.asteroidos.powerd.ProfileManager"

        function handleError(error) {
            console.log("Profile Edit D-Bus error:", error)
        }

        function loadProfile() {
            if (isNewProfile) {
                profile = {
                    "id": "",
                    "name": qsTrId("id-new-profile"),
                    "icon": "ios-battery-outline",
                    "color": "#2196F3",
                    "sensors": {
                        "accelerometer": "medium",
                        "gyroscope": "medium",
                        "heart_rate": "medium",
                        "hrv": "sleep_only",
                        "spo2": "off",
                        "barometer": "low",
                        "compass": "on_demand",
                        "ambient_light": "low",
                        "gps": "off"
                    },
                    "radios": {
                        "ble": {
                            "state": "on",
                            "sync_mode": "interval",
                            "interval_hours": 2,
                            "disable_during_sleep": false
                        },
                        "wifi": {
                            "state": "off",
                            "sync_mode": "manual"
                        },
                        "lte": {
                            "state": "off"
                        },
                        "nfc": {
                            "state": "off"
                        }
                    },
                    "system": {
                        "background_sync": "when_radios_on",
                        "always_on_display": true,
                        "tilt_to_wake": true
                    },
                    "automation": {
                        "battery_rules": [],
                        "time_rules": [],
                        "workout_profiles": {}
                    }
                }
            } else {
                typedCall("GetProfile", [profileId], function(result) {
                    profile = JSON.parse(result)
                }, handleError)
            }
        }

        Component.onCompleted: {
            loadProfile()
        }
    }

    function saveProfile() {
        var profileJson = JSON.stringify(profile)
        
        if (isNewProfile) {
            powerd.typedCall("AddProfile", [profileJson], function(newId) {
                if (newId) {
                    layerStack.pop(root)
                }
            }, powerd.handleError)
        } else {
            powerd.typedCall("UpdateProfile", [profileJson], function(success) {
                if (success) {
                    layerStack.pop(root)
                }
            }, powerd.handleError)
        }
    }

    function deleteProfile() {
        powerd.typedCall("DeleteProfile", [profileId], function(success) {
            if (success) {
                layerStack.pop(root)
            }
        }, powerd.handleError)
    }

    property string rowHeight: Dims.h(15)

    Flickable {
        anchors.fill: parent
        anchors.topMargin: Dims.h(15)
        anchors.bottomMargin: Dims.h(5)
        contentHeight: contentColumn.implicitHeight
        clip: true

        Column {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0

            Item {
                width: parent.width
                height: Dims.h(3)
            }

            Label {
                width: parent.width
                height: Dims.h(10)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                //% "Sensors"
                text: qsTrId("id-sensors")
                font.pixelSize: Dims.l(6)
                opacity: 0.8
            }

            RowSeparator {}

            OptionCycler {
                height: rowHeight
                width: parent.width
                //% "Accelerometer"
                text: qsTrId("id-accelerometer")
                valueArray: ["off", "low", "medium", "high", "workout"]
                currentValue: profile.sensors ? profile.sensors.accelerometer : "medium"
                onValueChanged: {
                    if (profile.sensors) {
                        profile.sensors.accelerometer = value
                    }
                }
            }

            RowSeparator {}

            OptionCycler {
                height: rowHeight
                width: parent.width
                //% "Gyroscope"
                text: qsTrId("id-gyroscope")
                valueArray: ["off", "low", "medium", "high", "workout"]
                currentValue: profile.sensors ? profile.sensors.gyroscope : "medium"
                onValueChanged: {
                    if (profile.sensors) {
                        profile.sensors.gyroscope = value
                    }
                }
            }

            RowSeparator {}

            OptionCycler {
                height: rowHeight
                width: parent.width
                //% "Heart Rate"
                text: qsTrId("id-heart-rate")
                valueArray: ["off", "low", "medium", "high", "workout"]
                currentValue: profile.sensors ? profile.sensors.heart_rate : "medium"
                onValueChanged: {
                    if (profile.sensors) {
                        profile.sensors.heart_rate = value
                    }
                }
            }

            RowSeparator {}

            OptionCycler {
                height: rowHeight
                width: parent.width
                //% "HRV"
                text: qsTrId("id-hrv")
                valueArray: ["off", "sleep_only", "always"]
                currentValue: profile.sensors ? profile.sensors.hrv : "sleep_only"
                onValueChanged: {
                    if (profile.sensors) {
                        profile.sensors.hrv = value
                    }
                }
            }

            RowSeparator {}

            OptionCycler {
                height: rowHeight
                width: parent.width
                //% "SpO2"
                text: qsTrId("id-spo2")
                valueArray: ["off", "periodic", "continuous"]
                currentValue: profile.sensors ? profile.sensors.spo2 : "off"
                onValueChanged: {
                    if (profile.sensors) {
                        profile.sensors.spo2 = value
                    }
                }
            }

            RowSeparator {}

            OptionCycler {
                height: rowHeight
                width: parent.width
                //% "Barometer"
                text: qsTrId("id-barometer")
                valueArray: ["off", "low", "high"]
                currentValue: profile.sensors ? profile.sensors.barometer : "low"
                onValueChanged: {
                    if (profile.sensors) {
                        profile.sensors.barometer = value
                    }
                }
            }

            RowSeparator {}

            OptionCycler {
                height: rowHeight
                width: parent.width
                //% "Compass"
                text: qsTrId("id-compass")
                valueArray: ["off", "on_demand", "continuous"]
                currentValue: profile.sensors ? profile.sensors.compass : "on_demand"
                onValueChanged: {
                    if (profile.sensors) {
                        profile.sensors.compass = value
                    }
                }
            }

            RowSeparator {}

            OptionCycler {
                height: rowHeight
                width: parent.width
                //% "Ambient Light"
                text: qsTrId("id-ambient-light")
                valueArray: ["off", "low", "high"]
                currentValue: profile.sensors ? profile.sensors.ambient_light : "low"
                onValueChanged: {
                    if (profile.sensors) {
                        profile.sensors.ambient_light = value
                    }
                }
            }

            RowSeparator {}

            OptionCycler {
                height: rowHeight
                width: parent.width
                //% "GPS"
                text: qsTrId("id-gps")
                valueArray: ["off", "periodic", "continuous"]
                currentValue: profile.sensors ? profile.sensors.gps : "off"
                onValueChanged: {
                    if (profile.sensors) {
                        profile.sensors.gps = value
                    }
                }
            }

            RowSeparator {}

            Item {
                width: parent.width
                height: Dims.h(5)
            }

            Label {
                width: parent.width
                height: Dims.h(10)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                //% "Radios"
                text: qsTrId("id-radios")
                font.pixelSize: Dims.l(6)
                opacity: 0.8
            }

            RowSeparator {}

            LabeledSwitch {
                height: rowHeight
                width: parent.width
                //% "Bluetooth"
                text: qsTrId("id-bluetooth")
                checked: profile.radios && profile.radios.ble ? profile.radios.ble.state === "on" : true
                onCheckedChanged: {
                    if (profile.radios && profile.radios.ble) {
                        profile.radios.ble.state = checked ? "on" : "off"
                    }
                }
            }

            RowSeparator {}

            OptionCycler {
                height: rowHeight
                width: parent.width
                visible: profile.radios && profile.radios.ble && profile.radios.ble.state === "on"
                //% "BLE Sync"
                text: qsTrId("id-ble-sync")
                valueArray: ["manual", "interval", "time_window"]
                currentValue: profile.radios && profile.radios.ble ? profile.radios.ble.sync_mode : "interval"
                onValueChanged: {
                    if (profile.radios && profile.radios.ble) {
                        profile.radios.ble.sync_mode = value
                    }
                }
            }

            RowSeparator {
                visible: profile.radios && profile.radios.ble && profile.radios.ble.state === "on"
            }

            OptionCycler {
                height: rowHeight
                width: parent.width
                visible: profile.radios && profile.radios.ble && profile.radios.ble.state === "on" && profile.radios.ble.sync_mode === "interval"
                //% "BLE Interval"
                text: qsTrId("id-ble-interval")
                valueArray: ["1", "2", "5", "10"]
                currentValue: profile.radios && profile.radios.ble ? String(profile.radios.ble.interval_hours) : "2"
                onValueChanged: {
                    if (profile.radios && profile.radios.ble) {
                        profile.radios.ble.interval_hours = parseInt(value)
                    }
                }
            }

            RowSeparator {
                visible: profile.radios && profile.radios.ble && profile.radios.ble.state === "on" && profile.radios.ble.sync_mode === "interval"
            }

            LabeledSwitch {
                height: rowHeight
                width: parent.width
                visible: profile.radios && profile.radios.ble && profile.radios.ble.state === "on" && profile.radios.ble.sync_mode === "interval"
                //% "Disable during sleep"
                text: qsTrId("id-ble-disable-sleep")
                checked: profile.radios && profile.radios.ble ? profile.radios.ble.disable_during_sleep : false
                onCheckedChanged: {
                    if (profile.radios && profile.radios.ble) {
                        profile.radios.ble.disable_during_sleep = checked
                    }
                }
            }

            RowSeparator {
                visible: profile.radios && profile.radios.ble && profile.radios.ble.state === "on" && profile.radios.ble.sync_mode === "interval"
            }

            LabeledSwitch {
                height: rowHeight
                width: parent.width
                //% "Wi-Fi"
                text: qsTrId("id-wifi")
                checked: profile.radios && profile.radios.wifi ? profile.radios.wifi.state === "on" : false
                onCheckedChanged: {
                    if (profile.radios && profile.radios.wifi) {
                        profile.radios.wifi.state = checked ? "on" : "off"
                    }
                }
            }

            RowSeparator {}

            OptionCycler {
                height: rowHeight
                width: parent.width
                visible: profile.radios && profile.radios.wifi && profile.radios.wifi.state === "on"
                //% "Wi-Fi Sync"
                text: qsTrId("id-wifi-sync")
                valueArray: ["manual", "interval", "time_window"]
                currentValue: profile.radios && profile.radios.wifi ? profile.radios.wifi.sync_mode : "manual"
                onValueChanged: {
                    if (profile.radios && profile.radios.wifi) {
                        profile.radios.wifi.sync_mode = value
                    }
                }
            }

            RowSeparator {
                visible: profile.radios && profile.radios.wifi && profile.radios.wifi.state === "on"
            }

            Item {
                width: parent.width
                height: Dims.h(5)
            }

            Label {
                width: parent.width
                height: Dims.h(10)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                //% "System"
                text: qsTrId("id-system")
                font.pixelSize: Dims.l(6)
                opacity: 0.8
            }

            RowSeparator {}

            LabeledSwitch {
                height: rowHeight
                width: parent.width
                //% "Always-on Display"
                text: qsTrId("id-always-on-display")
                checked: profile.system ? profile.system.always_on_display : true
                onCheckedChanged: {
                    if (profile.system) {
                        profile.system.always_on_display = checked
                    }
                }
            }

            RowSeparator {}

            LabeledSwitch {
                height: rowHeight
                width: parent.width
                //% "Tilt-to-wake"
                text: qsTrId("id-tilt-to-wake")
                checked: profile.system ? profile.system.tilt_to_wake : true
                onCheckedChanged: {
                    if (profile.system) {
                        profile.system.tilt_to_wake = checked
                    }
                }
            }

            RowSeparator {}

            OptionCycler {
                height: rowHeight
                width: parent.width
                //% "Background Sync"
                text: qsTrId("id-background-sync")
                valueArray: ["auto", "when_radios_on", "off"]
                currentValue: profile.system ? profile.system.background_sync : "when_radios_on"
                onValueChanged: {
                    if (profile.system) {
                        profile.system.background_sync = value
                    }
                }
            }

            RowSeparator {}

            Item {
                width: parent.width
                height: Dims.h(5)
            }

            Label {
                width: parent.width
                height: Dims.h(10)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                //% "Automation"
                text: qsTrId("id-automation")
                font.pixelSize: Dims.l(6)
                opacity: 0.8
            }

            RowSeparator {}

            ListItem {
                height: rowHeight
                width: parent.width
                //% "Battery Rules"
                title: qsTrId("id-battery-rules")
                iconName: "ios-battery-charging-outline"
                enabled: false
                opacity: 0.5
            }

            RowSeparator {}

            ListItem {
                height: rowHeight
                width: parent.width
                //% "Time Rules"
                title: qsTrId("id-time-rules")
                iconName: "ios-time-outline"
                enabled: false
                opacity: 0.5
            }

            RowSeparator {}

            ListItem {
                height: rowHeight
                width: parent.width
                //% "Workout Profiles"
                title: qsTrId("id-workout-profiles")
                iconName: "ios-walk-outline"
                enabled: false
                opacity: 0.5
            }

            RowSeparator {}

            Item {
                width: parent.width
                height: Dims.h(8)
            }

            Item {
                width: parent.width
                height: Dims.h(18)

                IconButton {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: Dims.h(15)
                    iconName: "ios-checkmark-circle-outline"
                    iconColor: "#4CAF50"

                    onClicked: saveProfile()
                }

                Label {
                    anchors.centerIn: parent
                    //% "Save"
                    text: qsTrId("id-save")
                    font.pixelSize: Dims.l(6)
                }
            }

            Item {
                width: parent.width
                height: Dims.h(18)
                visible: !isNewProfile

                IconButton {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: Dims.h(15)
                    iconName: "ios-trash-outline"
                    iconColor: "#F44336"

                    onClicked: {
                        deleteRemorse.execute(this, "", function() {
                            deleteProfile()
                        })
                    }
                }

                Label {
                    anchors.centerIn: parent
                    //% "Delete Profile"
                    text: qsTrId("id-delete-profile")
                    font.pixelSize: Dims.l(6)
                    color: "#F44336"
                }

                RemorseTimer {
                    id: deleteRemorse
                }
            }

            Item {
                width: parent.width
                height: Dims.h(5)
            }
        }
    }

    PageHeader {
        text: profile.name || qsTrId("id-profiles")
    }
}
