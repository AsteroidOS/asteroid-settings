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

#ifndef VOLUMECONTROL_H
#define VOLUMECONTROL_H

#include <QObject>
#include <QMediaPlayer>

class ComMeegoMainVolume2Interface;

class VolumeControl : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)

public:
    VolumeControl(QObject *parent = NULL);
    int volume() const { return volumePercentage; }
    void setVolume(int volume);

signals:
    void volumeChanged();

private:
    void setSteps(uint stepCount, uint currentStep);
    ComMeegoMainVolume2Interface *m_volIface = nullptr;
    int volumePercentage = 0;
    quint32 maximumVolume = 0;
    QMediaPlayer *effect = nullptr;
};

#endif

