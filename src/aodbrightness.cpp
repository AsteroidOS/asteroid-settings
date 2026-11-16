/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "aodbrightness.h"

#include <QDBusObjectPath>
#include <QDBusVariant>

#include <mce/dbus-names.h>

#include "mceinterface.h"

/* mce owns the backlight in low power mode too, so the always-on level is an
 * mce setting rather than a dconf key. An mce that does not know the key
 * answers with an error, which leaves available false and the row hidden. */
static const char *MceAodBrightness = "/system/osso/dsm/display/display_brightness_lpm";

AodBrightness::AodBrightness(QObject *parent) :
    QObject(parent),
    m_brightness(0),
    m_available(false)
{
    /* A drag across the slider lands one value per percent, and mce refilters
     * the brightness, starts a fade and writes its settings file on each one,
     * so the writes are coalesced and only the value the finger settles on
     * reaches the daemon. */
    m_writeTimer.setSingleShot(true);
    m_writeTimer.setInterval(200);
    connect(&m_writeTimer, SIGNAL(timeout()), this, SLOT(writeBrightness()));

    m_mceSignalIface = new ComNokiaMceSignalInterface(MCE_SERVICE, MCE_SIGNAL_PATH, QDBusConnection::systemBus(), this);
    connect(m_mceSignalIface, SIGNAL(config_change_ind(QString,QDBusVariant)), this, SLOT(configChange(QString,QDBusVariant)));

    m_mceIface = new ComNokiaMceRequestInterface(MCE_SERVICE, MCE_REQUEST_PATH, QDBusConnection::systemBus(), this);
    QDBusPendingReply<QDBusVariant> call = m_mceIface->get_config(QDBusObjectPath(MceAodBrightness));
    QDBusPendingCallWatcher *watcher = new QDBusPendingCallWatcher(call, this);
    QObject::connect(watcher, SIGNAL(finished(QDBusPendingCallWatcher *)),
                     this, SLOT(configReply(QDBusPendingCallWatcher *)));
}

AodBrightness::~AodBrightness()
{
    if (m_writeTimer.isActive())
        writeBrightness();
}

void AodBrightness::writeBrightness()
{
    m_mceIface->set_config(QDBusObjectPath(MceAodBrightness), QDBusVariant(m_brightness));
}

void AodBrightness::configReply(QDBusPendingCallWatcher *watcher)
{
    QDBusPendingReply<QDBusVariant> reply = *watcher;

    if (reply.isError()) {
        qWarning("Could not retrieve the always-on brightness: '%s'",
                 reply.error().message().toStdString().c_str());
    } else {
        m_available = true;
        emit availableChanged();
        configChange(MceAodBrightness, reply.value());
    }

    watcher->deleteLater();
}

void AodBrightness::configChange(const QString &key, const QDBusVariant &value)
{
    if (key != MceAodBrightness)
        return;

    int brightness = value.variant().toInt();
    if (brightness != m_brightness) {
        m_brightness = brightness;
        emit brightnessChanged();
    }
}

int AodBrightness::brightness() const
{
    return m_brightness;
}

bool AodBrightness::available() const
{
    return m_available;
}

void AodBrightness::setBrightness(int brightness)
{
    if (m_brightness == brightness)
        return;

    m_brightness = brightness;
    m_writeTimer.start();
    emit brightnessChanged();
}
