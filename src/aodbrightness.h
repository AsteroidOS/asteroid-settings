/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef AODBRIGHTNESS_H
#define AODBRIGHTNESS_H

#include <QObject>
#include <QtQml>
#include <QDBusPendingCallWatcher>
#include <QTimer>

class ComNokiaMceRequestInterface;
class ComNokiaMceSignalInterface;
class QDBusVariant;

class AodBrightness : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int brightness READ brightness WRITE setBrightness NOTIFY brightnessChanged)
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)

public:
    AodBrightness(QObject *parent = NULL);

    ~AodBrightness();

    int brightness() const;
    void setBrightness(int);
    bool available() const;

private slots:
    void writeBrightness();
    void configChange(const QString &key, const QDBusVariant &value);
    void configReply(QDBusPendingCallWatcher *watcher);

signals:
    void brightnessChanged();
    void availableChanged();

private:
    ComNokiaMceRequestInterface *m_mceIface;
    ComNokiaMceSignalInterface *m_mceSignalIface;
    QTimer m_writeTimer;

    int m_brightness;
    bool m_available;
};

#endif
