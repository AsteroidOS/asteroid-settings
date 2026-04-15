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
    property string activeProfileIcon: "ios-battery-outline"
    property int batteryLevel: 0
    property bool batteryCharging: false
    property string drainRate: ""
    property bool serviceAvailable: false

    ListModel {
        id: profilesModel
    }

    ListModel {
        id: topProfilesModel
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
                topProfilesModel.clear()
                
                for (var i = 0; i < profiles.length; i++) {
                    profilesModel.append(profiles[i])
                    if (i < 3) {
                        topProfilesModel.append(profiles[i])
                    }
                }
            }, handleError)
        }

        function loadActiveProfile() {
            typedCall("GetActiveProfile", [], function(result) {
                serviceAvailable = true
                activeProfileId = result
                
                typedCall("GetProfile", [activeProfileId], function(profileJson) {
                    var profile = JSON.parse(profileJson)
                    activeProfileName = profile.name
                    activeProfileIcon = profile.icon || "ios-battery-outline"
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
                    drainRate = prediction.drain_rate_percent_per_hour.toFixed(1) + "%/h"
                } else {
                    drainRate = ""
                }
            }, handleError)
        }

        Component.onCompleted: {
            loadProfiles()
            loadActiveProfile()
            loadBatteryState()
        }

        onServiceAvailableChanged: {
            if (available) {
                loadProfiles()
                loadActiveProfile()
                loadBatteryState()
            } else {
                serviceAvailable = false
            }
        }
    }

    Connections {
        target: powerd
        onActiveProfileChanged: {
            activeProfileId = id
            activeProfileName = name
            powerd.loadActiveProfile()
        }
        onProfilesChanged: {
            powerd.loadProfiles()
        }
        onBatteryLevelChanged: {
            batteryLevel = level
            batteryCharging = charging
            powerd.loadBatteryState()
        }
    }

    Component {
        id: profileSelectorLayer
        ProfileSelectorPage {}
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

            Rectangle {
                width: parent.width
                height: activeProfileCard.height
                color: "transparent"

                MouseArea {
                    id: activeProfileCard
                    anchors.fill: parent
                    width: parent.width
                    height: Dims.h(30)

                    onClicked: layerStack.push(profileSelectorLayer)

                    Column {
                        anchors.centerIn: parent
                        width: parent.width * 0.9
                        spacing: Dims.h(2)

                        Label {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            //% "Active Profile"
                            text: qsTrId("id-active-profile")
                            font.pixelSize: Dims.l(5)
                            opacity: 0.6
                        }

                        Label {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: activeProfileIcon
                            font.pixelSize: Dims.l(20)
                            font.family: "weathericons"
                            opacity: serviceAvailable ? 1.0 : 0.3
                        }

                        Label {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: serviceAvailable ? activeProfileName : 
                                  //% "Service unavailable"
                                  qsTrId("id-service-unavailable")
                            font.pixelSize: Dims.l(6)
                            wrapMode: Text.WordWrap
                            opacity: serviceAvailable ? 1.0 : 0.6
                        }

                        Item {
                            width: parent.width
                            height: Dims.h(3)
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Dims.w(3)

                            Label {
                                text: batteryCharging ? "⚡" : "🔋"
                                font.pixelSize: Dims.l(5)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Label {
                                text: batteryLevel + "%"
                                font.pixelSize: Dims.l(5)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Label {
                                text: drainRate
                                font.pixelSize: Dims.l(4)
                                opacity: 0.6
                                anchors.verticalCenter: parent.verticalCenter
                                visible: drainRate !== "" && !batteryCharging
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: Dims.h(3)
            }

            RowSeparator {
                visible: topProfilesModel.count > 0
            }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                //% "Quick Switch"
                text: qsTrId("id-quick-switch")
                font.pixelSize: Dims.l(5)
                opacity: 0.6
                visible: topProfilesModel.count > 0
            }

            Repeater {
                model: topProfilesModel

                ListItem {
                    height: Dims.h(12)
                    width: parent.width
                    title: model.name
                    iconName: model.icon || "ios-battery-outline"
                    
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: Dims.w(5)
                        anchors.verticalCenter: parent.verticalCenter
                        width: Dims.w(6)
                        height: Dims.h(6)
                        radius: Math.min(width, height) / 2
                        color: "transparent"
                        border.color: "#FFFFFF"
                        border.width: Dims.w(0.5)
                        visible: model.id === activeProfileId

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.6
                            height: parent.height * 0.6
                            radius: Math.min(width, height) / 2
                            color: "#FFFFFF"
                        }
                    }

                    onClicked: {
                        if (model.id !== activeProfileId) {
                            powerd.typedCall("SetActiveProfile", [model.id], function(success) {
                                if (success) {
                                    activeProfileId = model.id
                                }
                            }, powerd.handleError)
                        }
                    }
                }
            }

            RowSeparator {}

            ListItem {
                height: Dims.h(12)
                width: parent.width
                //% "All Profiles"
                title: qsTrId("id-all-profiles")
                iconName: "ios-list-outline"
                onClicked: layerStack.push(profileSelectorLayer)
            }

            RowSeparator {}

            ListItem {
                height: Dims.h(12)
                width: parent.width
                //% "Edit Profiles"
                title: qsTrId("id-edit-profiles")
                iconName: "ios-settings-outline"
                enabled: false
                opacity: 0.5
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
