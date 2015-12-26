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
    title: "Settings"

    LayerStack {
        id: layerStack
        Layer { id: timeLayer;       TimePage       { anchors.fill: parent } }
        Layer { id: dateLayer;       DatePage       { anchors.fill: parent } }
        Layer { id: bluetoothLayer;  BluetoothPage  { anchors.fill: parent } }
        Layer { id: brightnessLayer; BrightnessPage { anchors.fill: parent } }
        Layer { id: screenLayer;     ScreenPage     { anchors.fill: parent } }
        Layer { id: watchfaceLayer;  WatchfacePage  { anchors.fill: parent } }
        Layer { id: poweroffLayer;   PoweroffPage   { anchors.fill: parent } }
        Layer { id: restartLayer;    RestartPage    { anchors.fill: parent } }
        Layer { id: aboutLayer;      AboutPage      { anchors.fill: parent } }
    }

    GridLayout {
        id: grid
        anchors.fill: parent
        columns: 3
        rows: 3
        
        GridItem {
            title: "Time"
            iconName: "clock-outline"
            onClicked: timeLayer.show()
        }
        GridItem {
            title: "Date"
            iconName: "calendar-outline"
            onClicked: dateLayer.show()
        }
        GridItem {
            title: "Bluetooth"
            iconName: "cloud-outline" // bluetooth would probably be more suited but it's not available in outline!
            onClicked: bluetoothLayer.show()
        }
        GridItem {
            title: "Brightness"
            iconName: "sunny-outline"
            onClicked: brightnessLayer.show()
        }
        GridItem {
            title: "Screen"
            iconName: "monitor-outline"
            onClicked: screenLayer.show()
        }
        GridItem {
            title: "Watchface"
            iconName: "color-wand-outline"
            onClicked: watchfaceLayer.show()
        }
        GridItem {
            title: "Power Off"
            iconName: "bolt-outline" // power would probably be more suited but it's not available in outline!
            onClicked: poweroffLayer.show()
        }
        GridItem {
            title: "Restart"
            iconName: "reload"
            onClicked: restartLayer.show()
        }
        GridItem {
            title: "About"
            iconName: "help-outline"
            onClicked: aboutLayer.show()
        }
    }
}
