/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 * SPDX-FileCopyrightText: 2023 Arseniy Movshev <dodoradio@outlook.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import Nemo.Configuration
import QtQuick
import org.asteroid.controls
import org.asteroid.utils

/*
 * Host page for one face's settings and its remove action, pushed from the
 * selector on a long-press. The face itself is instantiated here, hidden and
 * on demand: the selector's cheap source scan only detects that a settingsPage
 * exists, while the actual settings UI is a Component on the face root and
 * needs an instance to come from. A user face without settings collapses to
 * the bare remove target; a stock face shows settings only.
 */
Item {
    id: container

    // Injected by LayerStack.push.
    property int depth
    property var pop
    // Set by the pusher: no reliance on unqualified context lookups.
    property string watchfaceName: ""
    property string watchfaceFile: ""
    property bool isStock: false
    property var store
    readonly property bool scanHasSettings: store.faceHasSettings(watchfaceName)
    readonly property bool hasSettings: faceLoader.status === Loader.Ready && faceLoader.item && typeof faceLoader.item.settingsPage !== "undefined"

    ConfigurationValue {
        id: activeWatchface

        key: "/desktop/asteroid/watchface"
        defaultValue: "file:///usr/share/asteroid-launcher/watchfaces/000-default-digital.qml"
    }

    // The on-demand face instance, loaded only when the source scan found a
    // settingsPage, and never shown: it exists to hand over that Component.
    Loader {
        id: faceLoader

        visible: false
        width: parent.width
        height: parent.height
        asynchronous: true
        source: container.scanHasSettings ? container.watchfaceFile : ""
    }

    // Bare remove target for a user face with no settings: a large centered
    // trash icon. The tap area is the icon and a generous margin around it,
    // not the whole page, so the header cannot start a removal.
    Item {
        anchors.fill: parent
        visible: !container.scanHasSettings && !container.isStock

        Icon {
            id: bareTrash

            name: "ios-trash-outline"
            color: "#FF3B30"
            width: Dims.l(32)
            height: Dims.l(32)
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: bareTrash
            anchors.margins: -Dims.l(8)
            onClicked: {
                //% "Remove"
                removeRemorse.action = qsTrId("id-remove") + "\n" + container.watchfaceName;
                removeRemorse.start();
            }
        }

    }

    Flickable {
        id: settingsFlick

        visible: container.scanHasSettings
        contentHeight: settingsColumn.height
        clip: true

        anchors {
            top: parent.top
            topMargin: pageHeader.height
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        Column {
            id: settingsColumn

            width: parent.width

            Loader {
                id: settingsLoader

                width: parent.width
                // Fill the viewport for the usual screen-sized settings page,
                // but let a taller page extend the content so it scrolls
                // instead of clipping.
                height: Math.max(container.height - pageHeader.height, item ? item.implicitHeight : 0)
                sourceComponent: container.hasSettings ? faceLoader.item.settingsPage : null
            }

            RowSeparator {
                visible: !container.isStock
            }

            Item {
                visible: !container.isStock
                width: parent.width
                height: visible ? Dims.h(24) : 0

                Column {
                    anchors.centerIn: parent

                    Icon {
                        name: "ios-trash-outline"
                        width: Dims.l(12)
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        width: Dims.l(70)
                        horizontalAlignment: Text.AlignHCenter
                        //% "Remove"
                        text: qsTrId("id-remove")
                        anchors.horizontalCenter: parent.horizontalCenter

                        font {
                            pixelSize: Dims.l(8)
                            family: "Noto Sans"
                            styleName: "SemiCondensed SemiBold"
                        }

                    }

                }

                HighlightBar {
                    onClicked: {
                        //% "Remove"
                        removeRemorse.action = qsTrId("id-remove") + " " + container.watchfaceName;
                        removeRemorse.start();
                    }
                }

            }

            Item {
                width: parent.width
                height: DeviceSpecs.hasRoundScreen ? Dims.l(8) : 0
            }

        }

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
            if (activeWatchface.value === container.watchfaceFile)
                activeWatchface.value = activeWatchface.defaultValue;

            // Remove first, pop after: the pop destroys this page, and only a
            // deferred-deletion accident would let a statement after it run.
            container.store.remove(container.watchfaceName);
            container.pop();
        }
    }

    PageHeader {
        id: pageHeader

        text: container.watchfaceName
    }

}
