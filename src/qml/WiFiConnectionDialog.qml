/*
 * Copyright (C) 2023 - Arseniy Movshev <dodoradio@outlook.com>
 *               2017-2022 - Chupligin Sergey <neochapay@gmail.com>
 *               2021 - Darrel Griët <idanlcontact@gmail.com>
 *               2016 - Sylvia van Os <iamsylvie@openmailbox.org>
 *               2015 - Florent Revest <revestflo@gmail.com>
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

/* A large proportion of this code has been referenced from Nemomobile-UX Glacier-Settings, published at https://github.com/nemomobile-ux/glacier-settings/blob/master/src/plugins/wifi/WifiSettings.qml
 */

import QtQuick 2.9
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import Connman 0.2
import QtQuick.VirtualKeyboard 2.4

Item {
    id: dialogItem
    property var modelData

    InputPanel {
        id: inputPanel
        z: 99
        visible: active
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: -Dims.h(25)
        height: Dims.h(100)

        width: Dims.w(100)
        externalLanguageSwitchEnabled: false
    }

    UserAgent {
        id: userAgent
        onUserInputRequested: {
            var view = {
                "fields": []
            };
            for (var key in fields) {
                view.fields.push({
                                    "name": key,
                                    "id": key.toLowerCase(),
                                    "type": fields[key]["Type"],
                                    "requirement": fields[key]["Requirement"]
                                });
                console.log(key + ":");
                for (var inkey in fields[key]) {
                    console.log("    " + inkey + ": " + fields[key][inkey]);
                }
            }
            userAgent.sendUserReply({"Passphrase": passphraseField.text})
        }

        onErrorReported: {
            console.log("Got error from model: " + error);
            failDialog.subLabelText = error;
            failDialog.open();
        }
    }
    Connections {
        target: modelData
        function onConnectRequestFailed(error) {
            console.log(error)
        }

        function onConnectedChanged(connected) {
            if(connected) {
                layerStack.pop(layerStack.currentLayer);
            }
        }
    }
    Flickable {
        anchors.fill: parent
        anchors.margins: Dims.l(15)
        contentHeight: contentColumn.implicitHeight
        Column {
            id: contentColumn
            width: parent.width
            Item {height: dialogItem.height*0.15; width: parent.width}
            Label {
                text: modelData.name
                font.pixelSize: Dims.l(6)
            }
            Label {
                id: identityLabel
                text: qsTr("Login")+":"
                font.pixelSize: Dims.l(6)
                visible: modelData.securityType === NetworkService.SecurityIEEE802
            }

            TextField {
                id: identityField
                text: modelData.identity
                width: parent.width
                visible: modelData.securityType === NetworkService.SecurityIEEE802
            }

            Label {
                id: passphraseLabel
                text: qsTr("Password")+":"
                font.pixelSize: Dims.l(6)
                visible: !(modelData.securityType == NetworkService.SecurityNone)
            }

            TextField {
                id: passphraseField
                text: modelData.passphrase
                echoMode: TextInput.Password //smartwatches are hard to type on. it is worth adding a 'show password' button for this field
                width: parent.width
                visible: !(modelData.securityType == NetworkService.SecurityNone)
            }
            LabeledSwitch {
                id: autoConnectCheckBox
                width: parent.width
                height: Dims.l(20)
                text: "autoconnect"
            }

            IconButton {
                iconName: "ios-checkmark-circle"
                height: width
                width: parent.width*0.3
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    modelData.passphrase = passphraseField.text;
                    modelData.identity = identityField.text
                    modelData.autoConnect = autoConnectCheckBox.checked
                    modelData.requestConnect();
                }
            }
        }
    }
}