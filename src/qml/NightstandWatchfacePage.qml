/*
 * Copyright (C) 2022 - Timo Könnecke <github.com/eLtMosen>
 *               2022 - Darrel Griët <dgriet@gmail.com>
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

import QtQuick 2.9
import QtGraphicalEffects 1.12
import Qt.labs.folderlistmodel 2.1
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import Nemo.Configuration 1.0
import Nemo.Time 1.0

Item {

    property alias displayAmbient: compositor.displayAmbient
    property string assetPath: "file:///usr/share/asteroid-launcher/"
    property alias watchface: watchfaceNightstandSource.value

    ConfigurationValue {
        id: watchfaceNightstandSource
        key: "/desktop/asteroid/nightstand/watchface"
        defaultValue: assetPath + "watchfaces/005-analog-nordic.qml"
    }

    ConfigurationValue {
        id: wallpaperSource
        key: "/desktop/asteroid/background-filename"
        defaultValue: "file:///usr/share/asteroid-launcher/wallpapers/full/000-flatmesh.qml"
    }

    ConfigurationValue {
        id: use12H
        key: "/org/asteroidos/settings/use-12h-format"
        defaultValue: false
    }

    QtObject {
        id: compositor
        property bool displayAmbient: false
    }

    WatchfaceSelector {
        anchors.fill: parent
    }
}
