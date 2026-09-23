/*
 * Copyright (C) 2026 - Darrel Griët <dgriet@gmail.com>
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

#include "coprocessor.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDebug>

static const char *Service = "org.asteroid.Coprocessor";
static const char *DisplayPath = "/Display";
static const char *HandsPath = "/Hands";
static const char *DisplayInterface = "org.asteroid.Coprocessor.Display";
static const char *HandsInterface = "org.asteroid.Coprocessor.Hands";
static const char *PropertiesInterface = "org.freedesktop.DBus.Properties";

static const unsigned int TimepieceModeCapability = 1u << 1;
static const unsigned int HandsCapability = 1u << 6;

Coprocessor::Coprocessor(QObject *parent)
    : QObject(parent)
    , m_watcher(Service, QDBusConnection::sessionBus(),
                QDBusServiceWatcher::WatchForRegistration | QDBusServiceWatcher::WatchForUnregistration)
{
    connect(&m_watcher, &QDBusServiceWatcher::serviceRegistered, this, &Coprocessor::fetchProperties);
    connect(&m_watcher, &QDBusServiceWatcher::serviceUnregistered, this, [this] { setAvailable(false); });

    QDBusConnection::sessionBus().connect(Service, DisplayPath, PropertiesInterface, "PropertiesChanged", this,
                                          SLOT(onDisplayPropertiesChanged(QString, QVariantMap, QStringList)));

    fetchProperties();
}

void Coprocessor::fetchProperties()
{
    QDBusMessage getAll = QDBusMessage::createMethodCall(Service, DisplayPath, PropertiesInterface, "GetAll");
    getAll << QString::fromLatin1(DisplayInterface);
    auto *watcher = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(getAll), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *watcher) {
        watcher->deleteLater();
        const QDBusPendingReply<QVariantMap> reply = *watcher;
        if (reply.isError())
            return;
        updateDisplay(reply.value());
        setAvailable(true);
    });
}

void Coprocessor::setAvailable(bool available)
{
    if (m_available == available)
        return;
    m_available = available;
    if (!available)
        m_display.clear();
    emit availableChanged();
    emit capabilitiesChanged();
}

void Coprocessor::updateDisplay(const QVariantMap &properties)
{
    const bool capabilitiesChanged = properties.contains("Capabilities")
        && properties.value("Capabilities") != m_display.value("Capabilities");
    m_display.insert(properties);
    if (capabilitiesChanged)
        emit this->capabilitiesChanged();
}

void Coprocessor::onDisplayPropertiesChanged(const QString &, const QVariantMap &changed, const QStringList &)
{
    updateDisplay(changed);
}

bool Coprocessor::available() const
{
    return m_available;
}

bool Coprocessor::supports(unsigned int capability) const
{
    return m_available && (m_display.value("Capabilities").toUInt() & capability);
}

bool Coprocessor::hasTimepieceMode() const
{
    return supports(TimepieceModeCapability);
}

bool Coprocessor::hasHands() const
{
    return supports(HandsCapability);
}

void Coprocessor::call(const QString &path, const QString &interface, const QString &method,
                         const QVariantList &arguments)
{
    QDBusMessage message = QDBusMessage::createMethodCall(Service, path, interface, method);
    message.setArguments(arguments);
    auto *watcher = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(message), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [method](QDBusPendingCallWatcher *watcher) {
        watcher->deleteLater();
        const QDBusPendingReply<bool> reply = *watcher;
        if (reply.isError())
            qWarning() << "Coprocessor" << method << "failed:" << reply.error().message();
        else if (!reply.value())
            qWarning() << "Coprocessor" << method << "failed";
    });
}

void Coprocessor::enterTimepieceMode()
{
    call(DisplayPath, DisplayInterface, "EnterTimepieceMode", {true});
}

void Coprocessor::moveHands(int minutePosition, int hourPosition)
{
    call(HandsPath, HandsInterface, "MoveAllHands", {QVariant::fromValue(QList<int>{minutePosition, hourPosition})});
}

void Coprocessor::calibrateHand(Hand hand, Rotation rotation, int steps)
{
    call(HandsPath, HandsInterface, "Calibrate", {static_cast<int>(hand), static_cast<int>(rotation), steps});
}

void Coprocessor::resumeWatchMode()
{
    call(HandsPath, HandsInterface, "ResumeWatchMode", {});
}
