/*
 * Copyright (C) 2022 - Ed Beroset <beroset@ieee.org>
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
 *
 * Based on a code from lipstick under the following license.
 *
 * Copyright (C) 2012 Jolla Ltd.
 * Contact: Robin Burchell <robin.burchell@jollamobile.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2.1 as published by the Free Software Foundation
 * and appearing in the file LICENSE.LGPL included in the packaging
 * of this file.
 */

#include "volumecontrol.h"
#include "VolumeControl2.h"
#include <QDBusMessage>
#include <QDBusConnection>
#include <QDBusArgument>
#include <QDBusReply>

/* 
 * This manipulates the master volume via the interface described here:
 * https://wiki.merproject.org/wiki/Nemo/Audio/MainVolume
 */

static const char *VOLUME_SERVICE = "com.Meego.MainVolume2";
static const char *VOLUME_PATH = "/com/meego/mainvolume2";

static QString getPulseaudioBusAddress()
{
    QString pa_bus_address{getenv("PULSE_DBUS_SERVER")};
    if (pa_bus_address == nullptr) {
        QDBusInterface pulseaudio("org.pulseaudio.Server", "/org/pulseaudio/server_lookup1", 
            "org.freedesktop.DBus.Properties");
        auto reply = pulseaudio.call("Get", "org.PulseAudio.ServerLookup1", "Address");
        if (reply.type() == QDBusMessage::ReplyMessage && reply.arguments().count() > 0) {
            auto addressArray = reply.arguments().first().value<QDBusVariant>().variant().toString().toLatin1();
            pa_bus_address = addressArray.data();
        }
    }
    return pa_bus_address;
}

VolumeControl::VolumeControl(QObject *parent) :
    QObject(parent)
{
    auto busname = getPulseaudioBusAddress();
    auto con = QDBusConnection::connectToPeer(busname, VOLUME_SERVICE);
    m_volIface = new ComMeegoMainVolume2Interface(VOLUME_SERVICE, VOLUME_PATH, con, this);
    setSteps(m_volIface->stepCount(), m_volIface->currentStep());
    connect(m_volIface, &ComMeegoMainVolume2Interface::StepsUpdated, this, &VolumeControl::setSteps);
}

void VolumeControl::setSteps(uint stepCount, uint currentStep)
{
    /* The pulseaudio API reports the step count (starting from 0), 
     * so the maximum volume is stepCount - 1
     */
    maximumVolume = stepCount-1;
    quint32 clampedVolume = qMin(currentStep, maximumVolume);
    int newVolumePercentage = 100.0 * clampedVolume / maximumVolume;

    if (volumePercentage != newVolumePercentage) {
        volumePercentage = newVolumePercentage;
        emit volumeChanged();
    }
}

void VolumeControl::setVolume(int volume)
{
    int newVolumePercentage = qBound(0, volume, 100);
    quint32 newVolume = maximumVolume / 100.0 * newVolumePercentage;
    if (volumePercentage != newVolumePercentage) {
        volumePercentage = newVolumePercentage;
        emit volumeChanged();
        if (m_volIface->isValid()) {
            m_volIface->setCurrentStep(newVolume);
            if(effect != NULL)
                effect->stop();
            effect = new QMediaPlayer(this);
            effect->setMedia(QUrl::fromLocalFile("/usr/share/sounds/notification.wav"));
            effect->play();
        }
    }
}
