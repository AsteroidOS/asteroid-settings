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

import QtQuick 2.2
import QtQuick.Layouts 1.1
import org.asteroid.controls 1.0

Application {
    id: app

    Component { id: languageLayer;   LanguagePage   { } }
    Component { id: timeLayer;       TimePage       { } }
    Component { id: dateLayer;       DatePage       { } }
    Component { id: bluetoothLayer;  BluetoothPage  { } }
    Component { id: brightnessLayer; BrightnessPage { } }
    Component { id: wallpaperLayer;  WallpaperPage  { } }
    Component { id: watchfaceLayer;  WatchfacePage  { } }
    Component { id: usbLayer;        USBPage        { } }
    Component { id: poweroffLayer;   PoweroffPage   { } }
    Component { id: aboutLayer;      AboutPage      { } }

    LayerStack { id: layerStack }

    Flickable {
        contentHeight: 10*Units.dp(25)
        contentWidth: width
        boundsBehavior: Flickable.DragOverBounds
        flickableDirection: Flickable.VerticalFlick
        anchors.fill: parent
        GridLayout {
            id: grid
            anchors.fill: parent
            columns: 1

            GridItem {
                title: qsTr("Language")
                iconName: "world-outline"
                onClicked: layerStack.push(languageLayer)
            }
            GridItem {
                title: qsTr("Time")
                iconName: "clock-outline"
                onClicked: layerStack.push(timeLayer)
            }
            GridItem {
                title: qsTr("Date")
                iconName: "calendar-outline"
                onClicked: layerStack.push(dateLayer)
            }
            GridItem {
                title: qsTr("Bluetooth")
                iconName: "cloud-outline" // bluetooth would probably be more suited but it's not available in outline!
                onClicked: layerStack.push(bluetoothLayer)
            }
            GridItem {
                title: qsTr("Brightness")
                iconName: "sunny-outline"
                onClicked: layerStack.push(brightnessLayer)
            }
            GridItem {
                title: qsTr("Wallpaper")
                iconName: "photos-outline"
                onClicked: layerStack.push(wallpaperLayer)
            }
            GridItem {
                title: qsTr("Watchface")
                iconName: "color-wand-outline"
                onClicked: layerStack.push(watchfaceLayer)
            }
            GridItem {
                title: qsTr("USB")
                iconName: "usb"
                onClicked: layerStack.push(usbLayer)
            }
            GridItem {
                title: qsTr("Power Off")
                iconName: "bolt-outline" // power would probably be more suited but it's not available in outline!
                onClicked: layerStack.push(poweroffLayer)
            }
            GridItem {
                title: qsTr("About")
                iconName: "help-outline"
                onClicked: layerStack.push(aboutLayer)
            }
        }
    }
}
