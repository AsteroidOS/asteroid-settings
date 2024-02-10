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
import org.asteroid.settings 1.0
import org.nemomobile.systemsettings 1.0

Flickable {
    AboutSettings {
        id: about
    }
    DiskUsage {
        id: diskUsage
    }
    SysInfo {
        id: info
    }

    Item {
        id: uptimeCounter
        readonly property int secondsPerDay: 60 * 60 * 24

        Timer {
            interval: 1000
            repeat: true
            triggeredOnStart: true
            running: true
            onTriggered: info.refresh()
        }
        function days() {
            return Math.floor(info.uptime / secondsPerDay)
        }
        function asString() {
            var now = info.uptime
            var days = Math.floor(now / secondsPerDay)
            var date = new Date(1000 * (now - days * secondsPerDay))
            return date.toISOString().substring(11, 19);
        }
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
        Repeater {
            model: [
                { label: qsTr("Build ID"), text: DeviceInfo.buildID },
                { label: qsTr("Codename"), text: DeviceInfo.machineName },
                { label: qsTr("Host name"), text: DeviceInfo.hostname },
                { label: qsTr("WLAN MAC"), text: about.wlanMacAddress },
                { label: qsTr("IMEI"), text: about.imei },
                { label: qsTr("Serial number"), text: about.serial },
                { label: qsTr("Vendor"), text: about.vendorName },
                { label: qsTr("Model"), text: about.vendorVersion },
                { label: qsTr("Total disk space"), text: qsTr("%L1 GB").arg(Math.round(about.totalDiskSpace() / 1e7)/100) },
                { label: qsTr("Available disk space"), text: qsTr("%L1 GB (%L2 %)").
                    arg(Math.round(about.availableDiskSpace() / 1e7)/100).
                    arg((100.0 * about.availableDiskSpace() / about.totalDiskSpace()).toFixed(0)) },
                { label: qsTr("Display size"), text: qsTr("%L1W x %L2H").arg(Dims.w(100)).arg(Dims.h(100)) },
                { label: qsTr("Kernel version"), text: kernelVersion },
                { label: qsTr("Qt version"), text: qtVersion },
                { label: qsTr("Uptime"), text: qsTr("%L1 days %L2").
                    arg(uptimeCounter.days()).
                    arg(uptimeCounter.asString())
                },
                { label: qsTr("Threads"), text: qsTr("%L1").arg(info.threads) },
                { label: qsTr("1,5,15 Minute loads"), text: qsTr("%L1, %L2, %L3").
                    arg(info.loads[0].toFixed(2)).
                    arg(info.loads[1].toFixed(2)).
                    arg(info.loads[2].toFixed(2))
                },
                { label: qsTr("Total memory"), text: qsTr("%L1 MB").arg(Math.round(info.totalRam * info.memUnit / 1e6)) },
                { label: qsTr("Free memory"), text: qsTr("%L1 MB (%L2 %)").
                    arg(Math.round(info.freeRam * info.memUnit / 1e6)).
                    arg((100.0 * info.freeRam / info.totalRam).toFixed(0))
                }
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
        Item {
            id: bottomSpacer
            height: parent.width*0.1
            width: height
        }
    }
}
