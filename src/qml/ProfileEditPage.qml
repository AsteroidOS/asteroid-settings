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
    property var profileData: ({})
    property bool isLoading: true

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
            isLoading = false
        }

        function loadProfile() {
            isLoading = true
            if (isNewProfile) {
                profileData = {
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
                isLoading = false
            } else {
                typedCall("GetProfile", [profileId], function(result) {
                    profileData = JSON.parse(result)
                    isLoading = false
                }, handleError)
            }
        }

        Component.onCompleted: {
            loadProfile()
        }
    }

    function updateSensor(sensorName, value) {
        if (!profileData.sensors) profileData.sensors = {}
        profileData.sensors[sensorName] = value
        profileDataChanged()
    }

    function updateRadioState(radioName, state) {
        if (!profileData.radios) profileData.radios = {}
        if (!profileData.radios[radioName]) profileData.radios[radioName] = {}
        profileData.radios[radioName].state = state
        profileDataChanged()
    }

    function updateRadioSyncMode(radioName, mode) {
        if (!profileData.radios) profileData.radios = {}
        if (!profileData.radios[radioName]) profileData.radios[radioName] = {}
        profileData.radios[radioName].sync_mode = mode
        profileDataChanged()
    }

    function updateRadioInterval(radioName, interval) {
        if (!profileData.radios) profileData.radios = {}
        if (!profileData.radios[radioName]) profileData.radios[radioName] = {}
        profileData.radios[radioName].interval_hours = interval
        profileDataChanged()
    }

    function updateRadioDisableSleep(radioName, disable) {
        if (!profileData.radios) profileData.radios = {}
        if (!profileData.radios[radioName]) profileData.radios[radioName] = {}
        profileData.radios[radioName].disable_during_sleep = disable
        profileDataChanged()
    }

    function updateSystemSetting(setting, value) {
        if (!profileData.system) profileData.system = {}
        profileData.system[setting] = value
        profileDataChanged()
    }

    signal profileDataChanged()

    function saveProfile() {
        var profileJson = JSON.stringify(profileData)
        
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

    Component {
        id: automationEditLayer
        AutomationEditPage {
            profileId: root.profileId
        }
    }

    Item {
        anchors.fill: parent
        visible: isLoading

        Label {
            anchors.centerIn: parent
            //% "Loading..."
            text: qsTrId("id-loading")
            font.pixelSize: Dims.l(6)
            opacity: 0.6
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: Dims.h(15)
        anchors.bottomMargin: Dims.h(5)
        contentHeight: contentColumn.implicitHeight
        clip: true
        visible: !isLoading

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
                height: Dims.h(15)
                width: parent.width
                //% "Accelerometer"
                text: qsTrId("id-accelerometer")
                valueArray: ["off", "low", "medium", "high", "workout"]
                currentValue: profileData.sensors ? profileData.sensors.accelerometer : "medium"
                onCurrentValueChanged: {
                    updateSensor("accelerometer", currentValue)
                }
            }

            RowSeparator {}

            OptionCycler {
                height: Dims.h(15)
                width: parent.width
                //% "Gyroscope"
                text: qsTrId("id-gyroscope")
                valueArray: ["off", "low", "medium", "high", "workout"]
                currentValue: profileData.sensors ? profileData.sensors.gyroscope : "medium"
                onCurrentValueChanged: {
                    updateSensor("gyroscope", currentValue)
                }
            }

            RowSeparator {}

            OptionCycler {
                height: Dims.h(15)
                width: parent.width
                //% "Heart Rate"
                text: qsTrId("id-heart-rate")
                valueArray: ["off", "low", "medium", "high", "workout"]
                currentValue: profileData.sensors ? profileData.sensors.heart_rate : "medium"
                onCurrentValueChanged: {
                    updateSensor("heart_rate", currentValue)
                }
            }

            RowSeparator {}

            OptionCycler {
                height: Dims.h(15)
                width: parent.width
                //% "HRV"
                text: qsTrId("id-hrv")
                valueArray: ["off", "sleep_only", "always"]
                currentValue: profileData.sensors ? profileData.sensors.hrv : "sleep_only"
                onCurrentValueChanged: {
                    updateSensor("hrv", currentValue)
                }
            }

            RowSeparator {}

            OptionCycler {
                height: Dims.h(15)
                width: parent.width
                //% "SpO2"
                text: qsTrId("id-spo2")
                valueArray: ["off", "periodic", "continuous"]
                currentValue: profileData.sensors ? profileData.sensors.spo2 : "off"
                onCurrentValueChanged: {
                    updateSensor("spo2", currentValue)
                }
            }

            RowSeparator {}

            OptionCycler {
                height: Dims.h(15)
                width: parent.width
                //% "Barometer"
                text: qsTrId("id-barometer")
                valueArray: ["off", "low", "high"]
                currentValue: profileData.sensors ? profileData.sensors.barometer : "low"
                onCurrentValueChanged: {
                    updateSensor("barometer", currentValue)
                }
            }

            RowSeparator {}

            OptionCycler {
                height: Dims.h(15)
                width: parent.width
                //% "Compass"
                text: qsTrId("id-compass")
                valueArray: ["off", "on_demand", "continuous"]
                currentValue: profileData.sensors ? profileData.sensors.compass : "on_demand"
                onCurrentValueChanged: {
                    updateSensor("compass", currentValue)
                }
            }

            RowSeparator {}

            OptionCycler {
                height: Dims.h(15)
                width: parent.width
                //% "Ambient Light"
                text: qsTrId("id-ambient-light")
                valueArray: ["off", "low", "high"]
                currentValue: profileData.sensors ? profileData.sensors.ambient_light : "low"
                onCurrentValueChanged: {
                    updateSensor("ambient_light", currentValue)
                }
            }

            RowSeparator {}

            OptionCycler {
                height: Dims.h(15)
                width: parent.width
                //% "GPS"
                text: qsTrId("id-gps")
                valueArray: ["off", "periodic", "continuous"]
                currentValue: profileData.sensors ? profileData.sensors.gps : "off"
                onCurrentValueChanged: {
                    updateSensor("gps", currentValue)
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
                height: Dims.h(15)
                width: parent.width
                //% "Bluetooth"
                text: qsTrId("id-bluetooth")
                checked: profileData.radios && profileData.radios.ble ? profileData.radios.ble.state === "on" : true
                onCheckedChanged: {
                    updateRadioState("ble", checked ? "on" : "off")
                }
            }

            RowSeparator {}

            OptionCycler {
                height: Dims.h(15)
                width: parent.width
                visible: profileData.radios && profileData.radios.ble && profileData.radios.ble.state === "on"
                //% "BLE Sync"
                text: qsTrId("id-ble-sync")
                valueArray: ["manual", "interval", "time_window"]
                currentValue: profileData.radios && profileData.radios.ble ? profileData.radios.ble.sync_mode : "interval"
                onCurrentValueChanged: {
                    updateRadioSyncMode("ble", currentValue)
                }
            }

            RowSeparator {
                visible: profileData.radios && profileData.radios.ble && profileData.radios.ble.state === "on"
            }

            OptionCycler {
                height: Dims.h(15)
                width: parent.width
                visible: profileData.radios && profileData.radios.ble && profileData.radios.ble.state === "on" && profileData.radios.ble.sync_mode === "interval"
                //% "BLE Interval"
                text: qsTrId("id-ble-interval")
                valueArray: ["1", "2", "5", "10"]
                currentValue: profileData.radios && profileData.radios.ble ? String(profileData.radios.ble.interval_hours) : "2"
                onCurrentValueChanged: {
                    updateRadioInterval("ble", parseInt(currentValue))
                }
            }

            RowSeparator {
                visible: profileData.radios && profileData.radios.ble && profileData.radios.ble.state === "on" && profileData.radios.ble.sync_mode === "interval"
            }

            LabeledSwitch {
                height: Dims.h(15)
                width: parent.width
                visible: profileData.radios && profileData.radios.ble && profileData.radios.ble.state === "on" && profileData.radios.ble.sync_mode === "interval"
                //% "Disable during sleep"
                text: qsTrId("id-ble-disable-sleep")
                checked: profileData.radios && profileData.radios.ble ? profileData.radios.ble.disable_during_sleep : false
                onCheckedChanged: {
                    updateRadioDisableSleep("ble", checked)
                }
            }

            RowSeparator {
                visible: profileData.radios && profileData.radios.ble && profileData.radios.ble.state === "on" && profileData.radios.ble.sync_mode === "interval"
            }

            LabeledSwitch {
                height: Dims.h(15)
                width: parent.width
                //% "Wi-Fi"
                text: qsTrId("id-wifi")
                checked: profileData.radios && profileData.radios.wifi ? profileData.radios.wifi.state === "on" : false
                onCheckedChanged: {
                    updateRadioState("wifi", checked ? "on" : "off")
                }
            }

            RowSeparator {}

            OptionCycler {
                height: Dims.h(15)
                width: parent.width
                visible: profileData.radios && profileData.radios.wifi && profileData.radios.wifi.state === "on"
                //% "Wi-Fi Sync"
                text: qsTrId("id-wifi-sync")
                valueArray: ["manual", "interval", "time_window"]
                currentValue: profileData.radios && profileData.radios.wifi ? profileData.radios.wifi.sync_mode : "manual"
                onCurrentValueChanged: {
                    updateRadioSyncMode("wifi", currentValue)
                }
            }

            RowSeparator {
                visible: profileData.radios && profileData.radios.wifi && profileData.radios.wifi.state === "on"
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
                height: Dims.h(15)
                width: parent.width
                //% "Always-on Display"
                text: qsTrId("id-always-on-display")
                checked: profileData.system ? profileData.system.always_on_display : true
                onCheckedChanged: {
                    updateSystemSetting("always_on_display", checked)
                }
            }

            RowSeparator {}

            LabeledSwitch {
                height: Dims.h(15)
                width: parent.width
                //% "Tilt-to-wake"
                text: qsTrId("id-tilt-to-wake")
                checked: profileData.system ? profileData.system.tilt_to_wake : true
                onCheckedChanged: {
                    updateSystemSetting("tilt_to_wake", checked)
                }
            }

            RowSeparator {}

            OptionCycler {
                height: Dims.h(15)
                width: parent.width
                //% "Background Sync"
                text: qsTrId("id-background-sync")
                valueArray: ["auto", "when_radios_on", "off"]
                currentValue: profileData.system ? profileData.system.background_sync : "when_radios_on"
                onCurrentValueChanged: {
                    updateSystemSetting("background_sync", currentValue)
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
                height: Dims.h(15)
                width: parent.width
                //% "Battery & Time Rules"
                title: qsTrId("id-battery-time-rules")
                iconName: "ios-cog-outline"
                
                onClicked: {
                    layerStack.push(automationEditLayer)
                }
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
        text: profileData.name || qsTrId("id-profiles")
    }
}
