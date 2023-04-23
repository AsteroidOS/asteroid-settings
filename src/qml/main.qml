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

import QtQuick 2.9
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import org.asteroid.settings 1.0

Application {
    id: app

    centerColor: "#0044A6"
    outerColor: "#00010C"

    Component { id: timeLayer;                  TimePage       { } }
    Component { id: dateLayer;                  DatePage       { } }
    Component { id: timezoneLayer;              TimezonePage   { } }
    Component { id: languageLayer;              LanguagePage   { } }
    Component { id: bluetoothLayer;             BluetoothPage  { } }
    Component { id: displayLayer;               DisplayPage    { } }
    Component { id: soundLayer;                 SoundPage      { } }
    Component { id: nightstandLayer;            NightstandPage { } }
    Component { id: nightstandWatchfaceLayer;   NightstandWatchfacePage { } }
    Component { id: unitsLayer;                 UnitsPage      { } }
    Component { id: wallpaperLayer;             WallpaperPage  { } }
    Component { id: watchfaceLayer;             WatchfacePage  { } }
    Component { id: launcherLayer;              LauncherPage   { } }
    Component { id: usbLayer;                   USBPage        { } }
    Component { id: poweroffLayer;              PoweroffPage   { } }
    Component { id: rebootLayer;                RebootPage     { } }
    Component { id: aboutLayer;                 AboutPage      { } }

    TiltToWake { id: tiltToWake }

    LayerStack {
        id: layerStack

        firstPage: firstPageComponent
    }

    Component {
        id: firstPageComponent

        Flickable {
            contentHeight: settingsColumn.implicitHeight
            contentWidth: width
            boundsBehavior: Flickable.DragOverBounds
            flickableDirection: Flickable.VerticalFlick

            Column {
                id: settingsColumn
                anchors.fill: parent

                Item { width: parent.width; height: DeviceInfo.hasRoundScreen ? Dims.h(6) : Dims.h(2) }

                ListItem {
                    //% "Time"
                    title: qsTrId("id-time-page")
                    iconName: "ios-clock-outline"
                    onClicked: layerStack.push(timeLayer)
                }
                ListItem {
                    //% "Date"
                    title: qsTrId("id-date-page")
                    iconName: "ios-calendar-outline"
                    onClicked: layerStack.push(dateLayer)
                }
                ListItem {
                    //% "Time zone"
                    title: qsTrId("id-timezone-page")
                    iconName: "ios-flag-outline"
                    onClicked: layerStack.push(timezoneLayer)
                }
                ListItem {
                    //% "Language"
                    title: qsTrId("id-language-page")
                    iconName: "ios-globe-outline"
                    onClicked: layerStack.push(languageLayer)
                }
                ListItem {
                    //% "Bluetooth"
                    title: qsTrId("id-bluetooth-page")
                    iconName: "ios-bluetooth-outline"
                    onClicked: layerStack.push(bluetoothLayer)
                }
                ListItem {
                    //% "Display"
                    title: qsTrId("id-display-page")
                    iconName: "ios-sunny-outline"
                    onClicked: layerStack.push(displayLayer)
                }
                ListItem {
                    //% "Sound"
                    title: qsTrId("id-sound-page")
                    iconName: "ios-volume-up"
                    onClicked: layerStack.push(soundLayer)
                    visible: DeviceInfo.hasSpeaker
                }
                ListItem {
                    //% "Nightstand"
                    title: qsTrId("id-nightstand-page")
                    iconName: "ios-moon-outline"
                    onClicked: layerStack.push(nightstandLayer)
                }
                ListItem {
                    //% "Units"
                    title: qsTrId("id-units-page")
                    iconName: "ios-speedometer-outline"
                    onClicked: layerStack.push(unitsLayer)
                }
                ListItem {
                    //% "Wallpaper"
                    title: qsTrId("id-wallpaper-page")
                    iconName: "ios-images-outline"
                    onClicked: layerStack.push(wallpaperLayer)
                }
                ListItem {
                    //% "Watchface"
                    title: qsTrId("id-watchface-page")
                    iconName: "ios-color-wand-outline"
                    onClicked: layerStack.push(watchfaceLayer)
                }
                ListItem {
                    //% "Launcher"
                    title: qsTrId("id-launcher-page")
                    iconName: "ios-apps-outline"
                    onClicked: layerStack.push(launcherLayer)
                }
                ListItem {
                    //% "USB"
                    title: qsTrId("id-usb-page")
                    iconName: "ios-usb"
                    onClicked: layerStack.push(usbLayer)
                }
                ListItem {
                    //% "Power Off"
                    title: qsTrId("id-poweroff-page")
                    iconName: "ios-power-outline"
                    onClicked: layerStack.push(poweroffLayer)
                }
                ListItem {
                    //% "Reboot"
                    title: qsTrId("id-reboot-page")
                    iconName: "ios-sync"
                    onClicked: layerStack.push(rebootLayer)
                }
                ListItem {
                    //% "About"
                    title: qsTrId("id-about-page")
                    iconName: "ios-help-circle-outline"
                    onClicked: layerStack.push(aboutLayer)
                }

                Item { width: parent.width; height: DeviceInfo.hasRoundScreen ? Dims.h(6) : Dims.h(2) }
            }
        }
    }
    function backToMainMenu() {
        while (layerStack.layers.length > 0) {
            layerStack.pop(layerStack.currentLayer)
        }
    }
}
