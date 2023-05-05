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

    property string rowHeight: Dims.h(25)

    Column {
        anchors.fill: parent

        Item { width: parent.width; height: Dims.l(25) }

        Item {
            width: parent.width
            height: rowHeight

            LabeledSwitch {
                anchors.fill: parent
                height: rowHeight
                //% "Use 12H format:"
                text: qsTrId("id-12h-format")
                checked: use12H.value
                onCheckedChanged: use12H.value = checked
            }
        }

        Item {
            width: parent.width
            height: rowHeight

            LabeledSwitch {
                anchors.fill: parent
                height: rowHeight
                //% "Use Fahrenheit:"
                text: qsTrId("id-fahrenheit")
                checked: useFahrenheit.value
                onCheckedChanged: useFahrenheit.value = checked
            }
        }
    }

    PageHeader {
        id: title
        text: qsTrId("id-units-page")
    }
}
