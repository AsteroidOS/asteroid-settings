/*
 * Copyright (C) 2015 - Florent Revest <revestflo@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 2.1 of the
 * License, or (at your option) any later version.
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
import QtQuick.Controls 1.2
import org.asteroid.controls 1.0

Application {
    id: app

    Component { id: timeLayer;       TimePage       { } }
    Component { id: dateLayer;       DatePage       { } }
    Component { id: bluetoothLayer;  BluetoothPage  { } }
    Component { id: brightnessLayer; BrightnessPage { } }
    Component { id: screenLayer;     ScreenPage     { } }
    Component { id: watchfaceLayer;  WatchfacePage  { } }
    Component { id: poweroffLayer;   PoweroffPage   { } }
    Component { id: restartLayer;    RestartPage    { } }
    Component { id: aboutLayer;      AboutPage      { } }

    LayerStack { id: layerStack }

    Flickable {
        contentHeight: DeviceInfo.hasRoundScreen ? 9*Units.dp(25) : height
        contentWidth: width
        boundsBehavior: DeviceInfo.hasRoundScreen ? Flickable.DragOverBounds : Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        anchors.fill: parent
        GridLayout {
            id: grid
            anchors.fill: parent
            columns: DeviceInfo.hasRoundScreen ? 1 : 3
            
            GridItem {
                title: "Time"
                iconName: "clock-outline"
                onClicked: layerStack.push(timeLayer)
            }
            GridItem {
                title: "Date"
                iconName: "calendar-outline"
                onClicked: layerStack.push(dateLayer)
            }
            GridItem {
                title: "Bluetooth"
                iconName: "cloud-outline" // bluetooth would probably be more suited but it's not available in outline!
                onClicked: layerStack.push(bluetoothLayer)
            }
            GridItem {
                title: "Brightness"
                iconName: "sunny-outline"
                onClicked: layerStack.push(brightnessLayer)
            }
            GridItem {
                title: "Screen"
                iconName: "monitor-outline"
                onClicked: layerStack.push(screenLayer)
            }
            GridItem {
                title: "Watchface"
                iconName: "color-wand-outline"
                onClicked: layerStack.push(watchfaceLayer)
            }
            GridItem {
                title: "Power Off"
                iconName: "bolt-outline" // power would probably be more suited but it's not available in outline!
                onClicked: layerStack.push(poweroffLayer)
            }
            GridItem {
                title: "Restart"
                iconName: "reload"
                onClicked: layerStack.push(restartLayer)
            }
            GridItem {
                title: "About"
                iconName: "help-outline"
                onClicked: layerStack.push(aboutLayer)
            }
        }
    }
}
