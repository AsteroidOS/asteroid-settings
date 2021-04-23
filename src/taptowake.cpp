/*
 * Copyright (C) 2020 - Darrel Griët <idanlcontact@gmail.com>
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
 * Based on a code from nemo-qml-plugin-systemsettings under the following license.
 *
 * Copyright (C) 2013 Jolla Ltd. <pekka.vuorela@jollamobile.com>
 *
 * You may use this file under the terms of the BSD license as follows:
 *
 * "Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *   * Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in
 *     the documentation and/or other materials provided with the
 *     distribution.
 *   * Neither the name of Nemo Mobile nor the names of its contributors
 *     may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
 */

#include "taptowake.h"
#include <QDBusMessage>
#include <QDBusConnection>
#include <QDBusArgument>
#include <dbus/dbus-glib-lowlevel.h>
#include <QTimer>
#include <QDebug>

#include <mce/dbus-names.h>
#include <mce/mode-names.h>
#include "mceiface.h"

static const char *MceTapToWakeEnabled = "/system/osso/dsm/powerkey/actions_gesture4";

TapToWake::TapToWake(QObject *parent) :
    QObject(parent),
    m_enabled(true)
{
    /* Setup change listener & get current values via async query */
    m_mceSignalIface = new ComNokiaMceSignalInterface(MCE_SERVICE, MCE_SIGNAL_PATH, QDBusConnection::systemBus(), this);
    connect(m_mceSignalIface, SIGNAL(config_change_ind(QString,QDBusVariant)), this, SLOT(configChange(QString,QDBusVariant)));

    m_mceIface = new ComNokiaMceRequestInterface(MCE_SERVICE, MCE_REQUEST_PATH, QDBusConnection::systemBus(), this);
    QDBusPendingReply<QDBusVariant> call = m_mceIface->get_config(QDBusObjectPath(MceTapToWakeEnabled));
    QDBusPendingCallWatcher *watcher = new QDBusPendingCallWatcher(call, this);
    QObject::connect(watcher, SIGNAL(finished(QDBusPendingCallWatcher *)),
                     this, SLOT(configReply(QDBusPendingCallWatcher *)));
}


void TapToWake::configReply(QDBusPendingCallWatcher *watcher)
{
    QDBusPendingReply<QDBusVariant> reply =  *watcher;

    if (reply.isError()) {
        qWarning("Could not retrieve mce settings: '%s'",
                 reply.error().message().toStdString().c_str());
    } else {
        QDBusVariant variant = reply.value();
        configChange(MceTapToWakeEnabled, variant);
    }

    watcher->deleteLater();
}

void TapToWake::configChange(const QString &key, const QDBusVariant &value)
{
    if (key == MceTapToWakeEnabled) {
        QString val = value.variant().toString();
        bool enabled = false;
        if (!QString::compare(val, "unblank")) {
            enabled = true;
        }
        if (enabled != m_enabled) {
            m_enabled = enabled;
            emit enabledChanged();
        }
    }
}

bool TapToWake::enabled() const
{
    return m_enabled;
}

void TapToWake::setEnabled(bool enabled)
{
    if (m_enabled != enabled) {
        m_enabled = enabled;
        if (m_enabled) {
            m_mceIface->set_config(QDBusObjectPath(MceTapToWakeEnabled), QDBusVariant("unblank"));
        } else {
            m_mceIface->set_config(QDBusObjectPath(MceTapToWakeEnabled), QDBusVariant(""));
        }
        emit enabledChanged();
    }
}
