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

#ifndef COPROCESSOR_H
#define COPROCESSOR_H

#include <QDBusServiceWatcher>
#include <QObject>
#include <QVariantMap>

class Coprocessor : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(bool hasTimepieceMode READ hasTimepieceMode NOTIFY capabilitiesChanged)
    Q_PROPERTY(bool hasHands READ hasHands NOTIFY capabilitiesChanged)

public:
    enum Hand { MinuteHand, HourHand };
    Q_ENUM(Hand)
    enum Rotation { Clockwise, CounterClockwise };
    Q_ENUM(Rotation)

    explicit Coprocessor(QObject *parent = nullptr);

    bool available() const;
    bool hasTimepieceMode() const;
    bool hasHands() const;

    Q_INVOKABLE void enterTimepieceMode();
    Q_INVOKABLE void moveHands(int minutePosition, int hourPosition);
    Q_INVOKABLE void calibrateHand(Hand hand, Rotation rotation, int steps);
    Q_INVOKABLE void resumeWatchMode();

signals:
    void availableChanged();
    void capabilitiesChanged();

private slots:
    void onManagerPropertiesChanged(const QString &interface, const QVariantMap &changed, const QStringList &invalidated);

private:
    bool supports(unsigned int capability) const;
    void setAvailable(bool available);
    void fetchProperties();
    void updateManager(const QVariantMap &properties);
    void call(const QString &path, const QString &interface, const QString &method, const QVariantList &arguments);

    QDBusServiceWatcher m_watcher;
    bool m_available = false;
    QVariantMap m_manager;
};

#endif // COPROCESSOR_H
