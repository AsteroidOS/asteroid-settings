/*
 * Copyright (C) 2022 - Ed Beroset <beroset@ieee.org>
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

import QtQuick 2.9
import org.asteroid.utils 1.0
import org.asteroid.controls 1.0
import Process 1.0
import org.nemomobile.systemsettings 1.0

Flickable {
    AboutSettings {
        id: about
    }
    DiskUsage {
        id: diskUsage
    }

    Process {
        id: process
        onReadyRead: uptime.text = readAll();
    }

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: true
        onTriggered: process.start("/bin/cat", [ "/proc/uptime" ]);
    }

    contentHeight: contentcolumn.implicitHeight
    Column {
        id: contentcolumn
        anchors.fill: parent
        Item { //this acts as a spacer to put the logo in the middle of the screen.
            height: parent.width*0.1
            width: height
        }
        Icon {
            name: "logo-asteroidos"
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width*0.4
            height: width
        }
        Label {
            id: osLabel
            text: about.operatingSystemName
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Label {
            id: releaseLabel
            text: about.softwareVersion
            opacity: 0.8
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            id: uptime
        }

        Repeater {
            model: [
                { label: qsTr("Build ID"), text: DeviceInfo.buildID },
                { label: qsTr("Codename"), text: DeviceInfo.machineName },
                { label: qsTr("Host name"), text: DeviceInfo.hostname },
                { label: qsTr("WLAN MAC"), text: about.wlanMacAddress },
                { label: qsTr("IMEI"), text: about.imei },
                { label: qsTr("Serial number"), text: about.serial },
                { label: qsTr("Total disk space"), text: qsTr("%L1").arg(Math.round(about.totalDiskSpace() / 1e7)/100) + " GB" },
                { label: qsTr("Available disk space"), text: qsTr("%L1").arg(Math.round(about.availableDiskSpace() / 1e7)/100)
                            + " GB (" + (100.0 * about.availableDiskSpace() / about.totalDiskSpace()).toFixed(0) + "%)" },
                { label: qsTr("Display size"), text: Dims.w(100) + qsTr("W") + " x " + Dims.h(100) + qsTr("H") },
                { label: qsTr("Kernel version"), text: kernelVersion },
                { label: qsTr("Qt version"), text: qtVersion }
            ]
            delegate: Column {
                width: contentcolumn.width
                anchors.horizontalCenter: contentcolumn.horizontalCenter
                visible: modelData.text
                Item {
                    height: parent.width*0.05
                    width: height
                }
                Label {
                    text: modelData.label
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    text: modelData.text
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
