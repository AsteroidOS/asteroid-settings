/*
 * Copyright (C) 2017 - Florent Revest <revestflo@gmail.com>
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
import QtQuick.Layouts 1.3
import Nemo.Configuration 1.0
import org.asteroid.controls 1.0

Item {
    PageHeader {
        id: title
        text: qsTrId("id-units-page")
    }

    ConfigurationValue {
        id: use12H
        key: "/org/asteroidos/settings/use-12h-format"
        defaultValue: false
    }

    ConfigurationValue {
        id: useFahrenheit
        key: "/org/asteroidos/settings/use-fahrenheit"
        defaultValue: false
    }

    GridLayout {
        columns: 2
        anchors.fill: parent
        anchors.margins: Dims.l(15)

        Label {
            //% "Use 12H format:"
            text: qsTrId("id-12h-format")
            font.pixelSize: Dims.l(6)
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
            Layout.maximumWidth: Dims.w(50)
        }

        Switch {
            Component.onCompleted: checked = use12H.value
            onCheckedChanged: use12H.value = checked
            width: Dims.l(20)
        }

        Label {
            //% "Use Fahrenheit:"
            text: qsTrId("id-fahrenheit")
            font.pixelSize: Dims.l(6)
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
            Layout.maximumWidth: Dims.w(50)
        }

        Switch {
            Component.onCompleted: checked = useFahrenheit.value
            onCheckedChanged: useFahrenheit.value = checked
            width: Dims.l(20)
        }
    }
}

