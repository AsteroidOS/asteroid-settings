/*
 * Copyright (C) 2022 - Darrel Griët <dgriet@gmail.com>
 * Copyright (C) 2022 - Timo Könnecke <github.com/eLtMosen>
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

import QtQuick 2.9
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import org.asteroid.settings 1.0

Application {
    id: app

    centerColor: "#4b45b9"
    outerColor: "#161537"

    Component { id: timeLayer;       TimePage       { } }
    Component { id: dateLayer;       DatePage       { } }
    Component { id: languageLayer;   LanguagePage   { } }
    Component { id: bluetoothLayer;  BluetoothPage  { } }
    Component { id: displayLayer;    DisplayPage    { } }
    Component { id: soundLayer;      SoundPage      { } }
    Component { id: unitsLayer;      UnitsPage      { } }
    Component { id: wallpaperLayer;  WallpaperPage  { } }
    Component { id: watchfaceLayer;  WatchfacePage  { } }
    Component { id: launcherLayer;   LauncherPage  { } }
    Component { id: usbLayer;        USBPage        { } }
    Component { id: poweroffLayer;   PoweroffPage   { } }
    Component { id: rebootLayer;     RebootPage     { } }
    Component { id: aboutLayer;      AboutPage      { } }

    TiltToWake { id: tiltToWake }

    LayerStack {
        id: layerStack
        firstPage: firstPageComponent
    }

    Component {
        id: firstPageComponent
        Item {
            property var icon: ""

            ListModel {
                id: layerModel
                Component.onCompleted: {
                    append({
                        //% "Time"
                        title: qsTrId("id-time-page"),
                        iconName: "ios-clock-outline",
                        newLayer: timeLayer
                    })
                    append({
                        //% "Date"
                        title: qsTrId("id-date-page"),
                        iconName: "ios-calendar-outline",
                        newLayer: dateLayer
                    })

                    append({
                        //% "Language"
                        title: qsTrId("id-language-page"),
                        iconName: "ios-globe-outline",
                        newLayer: languageLayer
                    })
                    append({
                        //% "Bluetooth"
                        title: qsTrId("id-bluetooth-page"),
                        iconName: "ios-bluetooth-outline",
                        newLayer: bluetoothLayer
                    })
                    append({
                        //% "Display"
                        title: qsTrId("id-display-page"),
                        iconName: "ios-sunny-outline",
                        newLayer: displayLayer
                    })
                    if (DeviceInfo.hasSpeaker) {
                        append({
                            //% "Sound"
                            title: qsTrId("id-sound-page"),
                            iconName: "ios-volume-up",
                            newLayer: soundLayer
                        })
                    }
                    append({
                        //% "Units"
                        title: qsTrId("id-units-page"),
                        iconName: "ios-speedometer-outline",
                        newLayer: unitsLayer
                    })
                    append({
                        //% "Wallpaper"
                        title: qsTrId("id-wallpaper-page"),
                        iconName: "ios-images-outline",
                        newLayer: wallpaperLayer
                    })
                    append({
                        //% "Watchface"
                        title: qsTrId("id-watchface-page"),
                        iconName: "ios-color-wand-outline",
                        newLayer: watchfaceLayer
                    })
                    append({
                        //% "Launcher"
                        title: qsTrId("id-launcher-page"),
                        iconName: "ios-apps-outline",
                        newLayer: launcherLayer
                    })
                    append({
                        //% "USB"
                        title: qsTrId("id-usb-page"),
                        iconName: "ios-usb",
                        newLayer: usbLayer
                    })
                    append({
                        //% "Power Off"
                        title: qsTrId("id-poweroff-page"),
                        iconName: "ios-power-outline",
                        newLayer: poweroffLayer
                    })
                    append({
                        //% "Reboot"
                        title: qsTrId("id-reboot-page"),
                        iconName: "ios-sync",
                        newLayer: rebootLayer
                    })
                    append({
                        //% "About"
                        title: qsTrId("id-about-page"),
                        iconName: "ios-help-circle-outline",
                        newLayer: aboutLayer
                    })
                }
            }

            Spinner {
                id: settingsView
                anchors.fill: parent
                topOffset: 0.5
                preferredHighlightBegin: height / 2 - Dims.h(8)
                preferredHighlightEnd: height / 2 + Dims.h(8)
                model: layerModel
                delegate: MouseArea {
                    property bool isCurr: ListView.isCurrentItem
                    height: isCurr ? Dims.h(16) : Dims.h(13)
                    //Behavior on height { NumberAnimation { duration: 200 } }
                    width: settingsView.width
                    enabled: !settingsView.dragging

                    onClicked: layerStack.push(newLayer)
                    onIsCurrChanged: if (isCurr) icon = iconName

                    Label {
                        id: iconText
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Dims.l(9)
                        font.letterSpacing: Dims.l(0.3)
                        font.styleName: "SemiCondensed Medium"
                        style: Text.Normal
                        opacity: isCurr ? 1.0 : 0.6
                        scale: isCurr ? 1.3 : 0.8
                        text: title
                        Behavior on scale   { NumberAnimation { duration: 200 } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }
            }

            Rectangle {
                height: (settingsView.currentIndex == 0) ? Dims.l(37.5) : Dims.l(24)
                Behavior on height { NumberAnimation { duration: 200 } }
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                color: "#99161162"

                Icon {
                    name: icon
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: (settingsView.currentIndex == 0) ? Dims.l(8.75) : Dims.l(2)
                    width: Dims.l(20)
                    height: width
                    Behavior on anchors.topMargin { NumberAnimation { duration: 200 } }
                }
            }
        }
    }
}
