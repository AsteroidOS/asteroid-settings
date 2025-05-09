/*
 * Copyright (C) 2023 - Timo Könnecke <github.com/eLtMosen>
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
import Nemo.Configuration 1.0

Application {
    id: app

    centerColor: "#0044A6"
    outerColor: "#00010C"

    ConfigurationValue {
        id: options
        key: "/desktop/asteroid/quicksettings/options"
        defaultValue: {
            "batteryBottom": true,
            "batteryAnimation": true,
            "batteryColored": false
        }
    }

    Component { id: quickSettingsLayer;         QuickSettingsPage { } }
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
    Component { id: powerLayer;                 PowerPage      { } }
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

                Item { width: parent.width; height: DeviceSpecs.hasRoundScreen ? Dims.h(6) : Dims.h(2) }

                ListItem {
                    //% "Display"
                    title: qsTrId("id-display-page")
                    iconName: "ios-display-outline"
                    onClicked: layerStack.push(displayLayer)
                }
                ListItem {
                    //% "Nightstand"
                    title: qsTrId("id-nightstand-page")
                    iconName: "ios-moon-outline"
                    onClicked: layerStack.push(nightstandLayer)
                }
                ListItem {
                    //% "Quick Settings"
                    title: qsTrId("id-quicksettings-page")
                    iconName: options.value.batteryBottom ? "ios-quicksettings-batterybottom" : "ios-quicksettings-batterytop"
                    onClicked: layerStack.push(quickSettingsLayer)
                }
                ListItem {
                    //% "Sound"
                    title: qsTrId("id-sound-page")
                    iconName: "ios-sound-outline"
                    onClicked: layerStack.push(soundLayer)
                    visible: DeviceSpecs.hasSpeaker
                }
                ListItem {
                    //% "Wallpaper"
                    title: qsTrId("id-wallpaper-page")
                    iconName: "ios-wallpaper-outline"
                    onClicked: layerStack.push(wallpaperLayer)
                }
                ListItem {
                    //% "Watchface"
                    title: qsTrId("id-watchface-page")
                    iconName: "ios-watchface-outline"
                    onClicked: layerStack.push(watchfaceLayer)
                }
                ListItem {
                    //% "Launcher"
                    title: qsTrId("id-launcher-page")
                    iconName: "ios-launcher-outline"
                    onClicked: layerStack.push(launcherLayer)
                }
                ListItem {
                    //% "Time"
                    title: qsTrId("id-time-page")
                    iconName: "ios-clock-outline"
                    onClicked: layerStack.push(timeLayer)
                }
                ListItem {
                    //% "Date"
                    title: qsTrId("id-date-page")
                    iconName: "ios-date-outline"
                    onClicked: layerStack.push(dateLayer)
                }
                ListItem {
                    //% "Units"
                    title: qsTrId("id-units-page")
                    iconName: "ios-units-outline"
                    onClicked: layerStack.push(unitsLayer)
                }
                ListItem {
                    //% "Language"
                    title: qsTrId("id-language-page")
                    iconName: "ios-earth-outline"
                    onClicked: layerStack.push(languageLayer)
                }
                ListItem {
                    //% "Time zone"
                    title: qsTrId("id-timezone-page")
                    iconName: "ios-globe-outline"
                    onClicked: layerStack.push(timezoneLayer)
                }
                ListItem {
                    //% "Bluetooth"
                    title: qsTrId("id-bluetooth-page")
                    iconName: "ios-bluetooth-outline"
                    onClicked: layerStack.push(bluetoothLayer)
                }
                ListItem {
                    //% "USB"
                    title: qsTrId("id-usb-page")
                    iconName: "ios-usb"
                    onClicked: layerStack.push(usbLayer)
                }
                ListItem {
                    //% "Power"
                    title: qsTrId("id-power-page")
                    iconName: "ios-power-outline"
                    onClicked: layerStack.push(powerLayer)
                }
                ListItem {
                    //% "About"
                    title: qsTrId("id-about-page")
                    iconName: "ios-help-circle-outline"
                    onClicked: layerStack.push(aboutLayer)
                }

                Item { width: parent.width; height: DeviceSpecs.hasRoundScreen ? Dims.h(6) : Dims.h(2) }
            }
        }
    }
    function backToMainMenu() {
        while (layerStack.layers.length > 0) {
            layerStack.pop(layerStack.currentLayer)
        }
    }
}
