/*
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

import QtQuick 2.1
import QtGraphicalEffects 1.0
import Qt.labs.folderlistmodel 2.1
import org.nemomobile.configuration 1.0
import org.asteroid.controls 1.0

Rectangle {
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#777777" }
            GradientStop { position: 1.0; color: "#2d2d2d" }
        }
    }

    ConfigurationValue {
        id: watchfaceSource
        key: "/desktop/asteroid/watchface"
        defaultValue: "file:///usr/share/asteroid-launcher/watchfaces/000-default-digital.qml"
    }

    GridView {
        id: grid
        cellWidth: width/2
        cellHeight: height/2
        anchors.fill: parent

        model: FolderListModel {
            id: folderModel
            folder: "file:///usr/share/asteroid-launcher/watchfaces"
            nameFilters: ["*.qml"]
        }

        delegate: Component {
            id: fileDelegate
            Image {
                width: grid.width/2
                height: grid.height/2
                fillMode: Image.PreserveAspectFit
                smooth: true
                source: folderModel.folder + "/" + fileName.replace(".qml", ".jpg")
                MouseArea {
                    anchors.fill: parent
                    onClicked: watchfaceSource.value = folderModel.folder + "/" + fileName
                }

                BrightnessContrast {
                    anchors.fill: parent
                    source: parent
                    brightness: -0.4
                    visible: watchfaceSource.value == folderModel.folder + "/" + fileName
                }
                Icon {
                    color: "white"
                    name: "ios-checkmark-circle"
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    height: width
                    width: parent.width*0.3
                    visible: watchfaceSource.value == folderModel.folder + "/" + fileName
                }
            }
        }
    }
}
