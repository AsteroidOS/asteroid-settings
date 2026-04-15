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
            console.log("Profile List D-Bus error:", error)
        }

        function loadData() {
            typedCall("GetActiveProfile", [], function(result) {
                activeProfileId = result
            }, handleError)

            typedCall("GetProfiles", [], function(result) {
                var profiles = JSON.parse(result)
                profilesModel.clear()
                for (var i = 0; i < profiles.length; i++) {
                    profilesModel.append(profiles[i])
                }
            }, handleError)
        }

        Component.onCompleted: {
            loadData()
        }

        onServiceAvailableChanged: {
            if (available) {
                loadData()
            }
        }
    }

    Connections {
        target: powerd
        onActiveProfileChanged: {
            activeProfileId = id
        }
        onProfilesChanged: {
            powerd.loadData()
        }
    }

    Component {
        id: profileEditLayer
        ProfileEditPage {}
    }

    ListView {
        id: profileListView
        anchors.fill: parent
        anchors.topMargin: Dims.h(15)
        anchors.bottomMargin: Dims.h(5)
        model: profilesModel
        clip: true
        spacing: 0

        delegate: Item {
            width: parent.width
            height: listItem.height

            property bool isActive: model.id === activeProfileId
            property bool isDefault: model.id && (
                model.id.indexOf("ultra_saver") === 0 ||
                model.id.indexOf("health") === 0 ||
                model.id.indexOf("smartwatch") === 0 ||
                model.id.indexOf("performance") === 0
            )

            ListItem {
                id: listItem
                height: Dims.h(15)
                width: parent.width
                title: model.name
                iconName: model.icon || "ios-battery-outline"

                Rectangle {
                    anchors.fill: parent
                    color: "#FFFFFF"
                    opacity: isActive ? 0.1 : 0
                    z: -1
                }

                Label {
                    anchors.right: parent.right
                    anchors.rightMargin: Dims.w(8)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✓"
                    font.pixelSize: Dims.l(8)
                    visible: isActive
                }

                onClicked: {
                    layerStack.push(profileEditLayer, {profileId: model.id})
                }

                onPressAndHold: {
                    if (!isDefault) {
                        deleteRemorse.execute(listItem, "", function() {
                            powerd.typedCall("DeleteProfile", [model.id], function(success) {
                                if (success) {
                                    powerd.loadData()
                                }
                            }, powerd.handleError)
                        })
                    }
                }

                RemorseTimer {
                    id: deleteRemorse
                }
            }

            RowSeparator {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }

        footer: Item {
            width: parent.width
            height: addButton.height + Dims.h(5)

            ListItem {
                id: addButton
                height: Dims.h(15)
                width: parent.width
                //% "Add New Profile"
                title: qsTrId("id-add-new-profile")
                iconName: "ios-add-circle-outline"

                onClicked: {
                    layerStack.push(profileEditLayer, {profileId: "", isNewProfile: true})
                }
            }

            RowSeparator {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }

        Item {
            id: emptyState
            anchors.centerIn: parent
            width: parent.width * 0.8
            visible: profilesModel.count === 0

            Column {
                anchors.centerIn: parent
                spacing: Dims.h(3)
                width: parent.width

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    //% "No profiles available"
                    text: qsTrId("id-no-profiles")
                    font.pixelSize: Dims.l(6)
                    wrapMode: Text.WordWrap
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    //% "Service may be unavailable"
                    text: qsTrId("id-service-may-be-unavailable")
                    font.pixelSize: Dims.l(4)
                    opacity: 0.6
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    PageHeader {
        //% "Profiles"
        text: qsTrId("id-profiles")
    }
}
