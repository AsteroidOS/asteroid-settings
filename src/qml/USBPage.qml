/*
 * Copyright (C) 2016 - Sylvia van Os <iamsylvie@openmailbox.org>
 * Copyright (C) 2015 - Florent Revest <revestflo@gmail.com>
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

import QtQuick
import Nemo.DBus
import org.asteroid.controls

Item {
    property int depth
    id: root
    property var pop

    ListModel {
        id: usbModesModel
        //% "Charging only"
        ListElement { title: qsTrId("id-charging-only"); mode: "charging_only" }
        //% "SSH Mode"
        ListElement { title: qsTrId("id-ssh-mode"); mode: "developer_mode" }
        //% "ADB Mode"
        ListElement { title: qsTrId("id-adb-mode"); mode: "adb_mode" }
    }

    Spinner {
        id: usbModeLV
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: title.bottom
        height: Dims.h(60)
        model: usbModesModel

        delegate: SpinnerDelegate { text: title }
    }

    IconButton {
        iconName: "ios-checkmark-circle-outline"
        anchors { 
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: Dims.iconButtonMargin
        }

        onClicked: {
            usbmodedDbus.call("set_mode", [usbModesModel.get(usbModeLV.currentIndex).mode])
            usbmodedDbus.call("set_config", [usbModesModel.get(usbModeLV.currentIndex).mode])

            root.pop();
        }
    }

    Component.onCompleted: {
        usbmodedDbus.typedCall('get_config', [], function (mode) {
            var idx = 0; // charging_only fallback
            for (var i = 0; i < usbModesModel.count; i++) {
                if (usbModesModel.get(i).mode === mode) {
                    idx = i;
                    break;
                }
            }
            usbModeLV.forceLayout();
            usbModeLV.positionViewAtIndex(idx, ListView.SnapPosition);
            usbModeLV.currentIndex = idx;
        });
    }

    DBusInterface {
        id: usbmodedDbus
        bus: DBus.SystemBus
        service: "com.meego.usb_moded"
        path: "/com/meego/usb_moded"
        iface: "com.meego.usb_moded"
    }

    PageHeader {
        id: title
        text: qsTrId("id-usb-page")
    }
}

