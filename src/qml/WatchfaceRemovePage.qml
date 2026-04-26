/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

import Nemo.Configuration 1.0
import QtQuick 2.9
import org.asteroid.controls 1.0
import org.asteroid.settings 1.0
import org.asteroid.utils 1.0

Item {
    id: removePage

    property string watchfaceName: ""
    property string watchfaceFile: ""

    Icon {
        name: "ios-trash-outline"
        color: "#FF3B30"
        width: Dims.l(40)
        height: Dims.l(40)

        anchors {
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: -Dims.l(10)
            horizontalCenter: parent.horizontalCenter
        }

    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            //% "Remove"
            removeRemorse.action = qsTrId("id-remove") + "\n" + removePage.watchfaceName;
            removeRemorse.start();
        }
    }

    ConfigurationValue {
        id: activeWatchface

        key: "/desktop/asteroid/watchface"
        defaultValue: "file:///usr/share/asteroid-launcher/watchfaces/000-default-digital.qml"
    }
    
    PageHeader {
        id: pageHeader

        text: removePage.watchfaceName
    }

    RemorseTimer {
        id: removeRemorse

        duration: 3000
        gaugeSegmentAmount: 8
        gaugeStartDegree: -130
        gaugeEndFromStartDegree: 265
        //% "Tap to cancel"
        cancelText: qsTrId("id-tap-to-cancel")
        onTriggered: {
            console.log("[WFS] RemovePage onTriggered — watchfaceName:", removePage.watchfaceName);
            var targetPath = WatchfaceHelper.userAssetPath() + "watchfaces/" + removePage.watchfaceName + ".qml";
            if (activeWatchface.value === targetPath)
                activeWatchface.value = activeWatchface.defaultValue;

            layerStack.pop(layerStack.currentLayer);
            WatchfaceHelper.removeWatchface(removePage.watchfaceName);
        }
    }

}
