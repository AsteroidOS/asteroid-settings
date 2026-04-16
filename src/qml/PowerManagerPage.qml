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

    property string activeProfileId: ""
    property string activeProfileName: ""
    property string activeProfileIcon: "ios-battery-full"
    property int batteryLevel: 0
    property bool batteryCharging: false
    property string drainRate: ""
    property real drainRatePerHour: 0
    property var batteryHistory: []
    property bool serviceAvailable: false
    property bool isEmulator: false

    ListModel {
        id: profilesModel
    }

    DBusInterface {
        id: powerd
        bus: DBus.SystemBus
        service: "org.asteroidos.powerd"
        path: "/org/asteroidos/powerd"
        iface: "org.asteroidos.powerd.ProfileManager"

        signalsEnabled: true

        function handleError(error) {
            console.log("Power Manager D-Bus error:", error)
            serviceAvailable = false
        }

        function loadProfiles() {
            typedCall("GetProfiles", [], function(result) {
                serviceAvailable = true
                var profiles = JSON.parse(result)
                profilesModel.clear()
                for (var i = 0; i < profiles.length; i++) {
                    profilesModel.append(profiles[i])
                }
            }, handleError)
        }

        function loadActiveProfile() {
            typedCall("GetActiveProfile", [], function(result) {
                serviceAvailable = true
                activeProfileId = result

                typedCall("GetProfile", [{"type": "s", "value": activeProfileId}], function(profileJson) {
                    var profile = JSON.parse(profileJson)
                    activeProfileName = profile.name
                    activeProfileIcon = profile.icon || "ios-battery-full"
                }, handleError)
            }, handleError)
        }

        function loadBatteryState() {
            typedCall("GetCurrentState", [], function(result) {
                var state = JSON.parse(result)
                if (state.battery) {
                    batteryLevel = state.battery.level || 0
                    batteryCharging = state.battery.charging || false
                }
            }, handleError)
            
            typedCall("GetBatteryPrediction", [], function(result) {
                var prediction = JSON.parse(result)
                if (prediction.drain_rate_percent_per_hour) {
                    drainRatePerHour = prediction.drain_rate_percent_per_hour
                    drainRate = drainRatePerHour.toFixed(1) + "%/h"
                } else {
                    drainRatePerHour = 0
                    drainRate = ""
                }
            }, handleError)
        }

        function loadBatteryHistory() {
            typedCall("GetBatteryHistory",
                [{"type": "i", "value": 168}],
                function(result) {
                    var data = JSON.parse(result)
                    if (data.length > 10) {
                        batteryHistory = data
                    } else if (isEmulator) {
                        batteryHistory = generateSimulatedHistory()
                    }
                }, function() {
                    if (isEmulator) {
                        batteryHistory = generateSimulatedHistory()
                    }
                })
        }

        function activeProfileChanged(newId) {
            activeProfileId = newId
            loadActiveProfile()
        }

        function profilesChanged() {
            loadProfiles()
        }

        function batteryLevelChanged(newLevel, isCharging) {
            batteryLevel = newLevel
            batteryCharging = isCharging
            loadBatteryState()
            loadBatteryHistory()
        }

        Component.onCompleted: {
            detectEmulator()
            loadProfiles()
            loadActiveProfile()
            loadBatteryState()
            loadBatteryHistory()
        }
    }

    // Detect emulator by reading /etc/hostname (set to "emulator" in QEMU builds,
    // real watches have device codenames like "catfish", "beluga", "sturgeon", etc.)
    function detectEmulator() {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var hostname = (xhr.responseText || "").trim()
                isEmulator = (hostname === "emulator")
                if (isEmulator) {
                    console.log("PowerManager: Running on emulator — simulation data available")
                    // Re-try history now that we know we're on emulator
                    if (batteryHistory.length === 0) {
                        powerd.loadBatteryHistory()
                    }
                }
            }
        }
        xhr.open("GET", "file:///etc/hostname")
        xhr.send()
    }

    // Generate realistic 7-day simulated battery data for graph preview.
    // ONLY called when isEmulator is true (QEMU build) — never on real hardware.
    // Points every 2 hours matching daemon heartbeat interval.
    // Pattern: ~2 days drain → 2h charge → ~3 days drain → 2h charge → drain to now
    function generateSimulatedHistory() {
        if (!isEmulator) return []

        var now = Math.floor(Date.now() / 1000)
        var data = []
        var t = now - 7 * 24 * 3600
        var level = 100
        var STEP = 7200          // 2 hours
        var HOUR = 3600

        // Helper: drain rate per 2h step (base %/h * 2 + tiny noise)
        function drainStep(basePerHour) {
            return (basePerHour + (Math.random() - 0.5) * 0.3) * 2
        }
        // Helper: charge rate per 2h step
        function chargeStep(basePerHour) {
            return (basePerHour + (Math.random() - 0.5) * 2) * 2
        }

        // Phase 1: Drain ~2 days (48h) at ~2%/h
        var phase1End = t + 48 * HOUR
        while (t < phase1End && t < now) {
            data.push({timestamp: t, level: Math.round(level * 10) / 10, charging: false, profile: "balanced"})
            level -= drainStep(2.0)
            level = Math.max(0, level)
            t += STEP
        }

        // Phase 2: Charge ~2h at ~40%/h (fast charge)
        var phase2End = t + 2 * HOUR
        while (t < phase2End && t < now) {
            data.push({timestamp: t, level: Math.round(level * 10) / 10, charging: true, profile: "balanced"})
            level += chargeStep(40)
            level = Math.min(100, level)
            t += STEP
        }

        // Phase 3: Drain ~3 days (72h) at ~1.4%/h (power saver)
        var phase3End = t + 72 * HOUR
        while (t < phase3End && t < now) {
            data.push({timestamp: t, level: Math.round(level * 10) / 10, charging: false, profile: "power_saver"})
            level -= drainStep(1.4)
            level = Math.max(0, level)
            t += STEP
        }

        // Phase 4: If battery low, charge 2h then drain remaining time
        if (t < now && level < 25) {
            var phase4End = t + 2 * HOUR
            while (t < phase4End && t < now) {
                data.push({timestamp: t, level: Math.round(level * 10) / 10, charging: true, profile: "balanced"})
                level += chargeStep(38)
                level = Math.min(100, level)
                t += STEP
            }
        }
        while (t < now) {
            data.push({timestamp: t, level: Math.round(level * 10) / 10, charging: false, profile: "balanced"})
            level -= drainStep(1.8)
            level = Math.max(0, level)
            t += STEP
        }

        // Final point at now
        var finalLevel = batteryLevel > 0 ? batteryLevel : 61
        data.push({timestamp: now, level: finalLevel, charging: false, profile: "balanced"})
        return data
    }

    Component {
        id: profileSelectorLayer
        ProfileSelectorPage {}
    }

    Component {
        id: profileListLayer
        ProfileListPage {}
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: Dims.h(15)
        anchors.bottomMargin: Dims.h(15)
        contentHeight: contentColumn.implicitHeight
        clip: true

        Column {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Dims.h(2)

            Item {
                width: parent.width
                height: Dims.h(8)
            }

            MouseArea {
                width: parent.width
                height: profileCardColumn.height

                onClicked: layerStack.push(profileSelectorLayer)

                Column {
                    id: profileCardColumn
                    width: parent.width
                    spacing: Dims.h(1)

                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        //% "Active Profile"
                        text: qsTrId("id-active-profile")
                        font.pixelSize: Dims.l(6)
                        opacity: 0.6
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Dims.w(3)

                        Icon {
                            name: activeProfileIcon
                            width: Dims.l(8)
                            height: width
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: serviceAvailable ? 1.0 : 0.3
                        }

                        Label {
                            text: serviceAvailable ? activeProfileName :
                                  //% "Service unavailable"
                                  qsTrId("id-service-unavailable")
                            font.pixelSize: Dims.l(5)
                            wrapMode: Text.WordWrap
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: serviceAvailable ? 1.0 : 0.6
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: Dims.h(3)
            }

            RowSeparator {}

            ListItem {
                height: Dims.h(12)
                width: parent.width
                //% "Edit Profiles"
                title: qsTrId("id-edit-profiles")
                iconName: "ios-settings-outline"
                onClicked: layerStack.push(profileListLayer)
            }

            RowSeparator {}

            ListItem {
                height: Dims.h(12)
                width: parent.width
                //% "Automation"
                title: qsTrId("id-automation")
                iconName: "ios-timer-outline"
                enabled: false
                opacity: 0.5
            }

            RowSeparator {}

            Item {
                width: parent.width
                height: Dims.h(35)

                BatteryHistoryGraph {
                    anchors.fill: parent
                    anchors.leftMargin: Dims.w(2)
                    anchors.rightMargin: Dims.w(2)
                    historyData: batteryHistory
                    currentLevel: batteryLevel
                    drainRatePerHour: root.drainRatePerHour
                    isCharging: batteryCharging
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Dims.w(3)

                Label {
                    text: batteryLevel + "%"
                    font.pixelSize: Dims.l(8)
                    font.styleName: "SemiCondensed Light"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Label {
                    text: drainRate
                    font.pixelSize: Dims.l(4)
                    opacity: 0.6
                    anchors.verticalCenter: parent.verticalCenter
                    visible: drainRate !== "" && !batteryCharging
                }

                Label {
                    text: batteryCharging ? "⚡" : ""
                    font.pixelSize: Dims.l(5)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: batteryCharging
                }
            }

            Item {
                width: parent.width
                height: Dims.h(5)
            }
        }
    }

    PageHeader {
        //% "Power Manager"
        text: qsTrId("id-power-manager-page")
    }
}
