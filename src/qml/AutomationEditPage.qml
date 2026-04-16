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
    property var profile: ({})
    property var automation: ({})

    DBusInterface {
        id: powerd
        bus: DBus.SystemBus
        service: "org.asteroidos.powerd"
        path: "/org/asteroidos/powerd"
        iface: "org.asteroidos.powerd.ProfileManager"

        function handleError(error) {
            console.log("Automation Edit D-Bus error:", error)
        }

        function loadProfile() {
            typedCall("GetProfile", [{"type": "s", "value": profileId}], function(result) {
                var p = JSON.parse(result)
                profile = p
                automation = p.automation || {
                    "battery_rules": [],
                    "time_rules": [],
                    "workout_profiles": {}
                }
            }, handleError)
        }

        Component.onCompleted: {
            loadProfile()
        }
    }

    function saveAutomation() {
        profile.automation = automation
        var profileJson = JSON.stringify(profile)
        
        powerd.typedCall("UpdateProfile",
            [{"type": "s", "value": profileJson}],
            function(success) {
                if (success) {
                    layerStack.pop(root)
                }
            }, powerd.handleError)
    }

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
                //% "Battery Rules"
                text: qsTrId("id-battery-rules")
                font.pixelSize: Dims.l(6)
                opacity: 0.8
            }

            RowSeparator {}

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                //% "Switch profile when battery reaches threshold"
                text: qsTrId("id-battery-rules-desc")
                font.pixelSize: Dims.l(3)
                color: "#80FFFFFF"
                wrapMode: Text.WordWrap
                padding: Dims.w(4)
            }

            Repeater {
                model: automation.battery_rules || []

                Column {
                    width: parent.width
                    spacing: 0

                    ListItem {
                        id: batteryRuleItem
                        height: Dims.h(15)
                        width: parent.width
                        title: modelData.threshold + "% → " + modelData.switch_to_profile
                        iconName: "ios-battery-charging"
                    }

                    MouseArea {
                        anchors.fill: batteryRuleItem
                        onPressAndHold: {
                            deleteRuleRemorse.execute(batteryRuleItem, "", function() {
                                var rules = automation.battery_rules.slice()
                                rules.splice(index, 1)
                                automation.battery_rules = rules
                            })
                        }
                        onClicked: batteryRuleItem.clicked()
                    }

                    RemorseTimer {
                        id: deleteRuleRemorse
                    }

                    RowSeparator {}
                }
            }

            ListItem {
                height: Dims.h(15)
                width: parent.width
                //% "Add Battery Rule"
                title: qsTrId("id-add-battery-rule")
                iconName: "ios-add-circle-outline"
                enabled: false
                opacity: 0.5
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
                //% "Time Rules"
                text: qsTrId("id-time-rules")
                font.pixelSize: Dims.l(6)
                opacity: 0.8
            }

            RowSeparator {}

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                //% "Switch profile during time window"
                text: qsTrId("id-time-rules-desc")
                font.pixelSize: Dims.l(3)
                color: "#80FFFFFF"
                wrapMode: Text.WordWrap
                padding: Dims.w(4)
            }

            Repeater {
                model: automation.time_rules || []

                Column {
                    width: parent.width
                    spacing: 0

                    ListItem {
                        id: timeRuleItem
                        height: Dims.h(15)
                        width: parent.width
                        title: modelData.start + " - " + modelData.end + " → " + modelData.switch_to_profile
                        iconName: "ios-time-outline"
                    }

                    MouseArea {
                        anchors.fill: timeRuleItem
                        onPressAndHold: {
                            deleteTimeRuleRemorse.execute(timeRuleItem, "", function() {
                                var rules = automation.time_rules.slice()
                                rules.splice(index, 1)
                                automation.time_rules = rules
                            })
                        }
                        onClicked: timeRuleItem.clicked()
                    }

                    RemorseTimer {
                        id: deleteTimeRuleRemorse
                    }

                    RowSeparator {}
                }
            }

            ListItem {
                height: Dims.h(15)
                width: parent.width
                //% "Add Time Rule"
                title: qsTrId("id-add-time-rule")
                iconName: "ios-add-circle-outline"
                enabled: false
                opacity: 0.5
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
                //% "Workout Profiles"
                text: qsTrId("id-workout-profiles")
                font.pixelSize: Dims.l(6)
                opacity: 0.8
            }

            RowSeparator {}

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                //% "Assign profile for each workout type"
                text: qsTrId("id-workout-profiles-desc")
                font.pixelSize: Dims.l(3)
                color: "#80FFFFFF"
                wrapMode: Text.WordWrap
                padding: Dims.w(4)
            }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                //% "Configure in Workout app settings"
                text: qsTrId("id-workout-configure-in-app")
                font.pixelSize: Dims.l(3)
                color: "#80FFFFFF"
                wrapMode: Text.WordWrap
                padding: Dims.w(4)
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

                    onClicked: saveAutomation()
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
                height: Dims.h(5)
            }
        }
    }

    PageHeader {
        //% "Automation"
        text: qsTrId("id-automation")
    }
}
