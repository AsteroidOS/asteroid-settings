/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "watchfaceqmlprobe.h"
#include "watchfacehelper.h"

#include <QFile>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QRegularExpression>

namespace {
const QString kStockDir = QStringLiteral("/usr/share/asteroid-launcher/watchfaces/");
}

void WatchfaceQmlProbe::setQmlEngine(QQmlEngine *engine)
{
    m_engine = engine;
}

void WatchfaceQmlProbe::ensureEngine(QQmlEngine *fallback) const
{
    if (!m_engine)
        m_engine = fallback;
}

bool WatchfaceQmlProbe::moduleAvailable(const QString &uri) const
{
    const auto it = m_moduleAvail.constFind(uri);
    if (it != m_moduleAvail.constEnd())
        return it.value();

    QQmlEngine *engine = m_engine;
    if (!engine)
        return true; // uncached, so the real probe still runs once an engine exists

    // A face runs in the launcher, which shares this import path, so a module
    // missing here is missing for the face too.
    QQmlComponent probe(engine);
    probe.setData("import " + uri.toUtf8() + "\nimport QtQml\nQtObject {}", QUrl());
    const bool avail = probe.status() != QQmlComponent::Error;
    m_moduleAvail.insert(uri, avail);
    return avail;
}

QString WatchfaceQmlProbe::firstUnmetImport(const QString &qmlPath) const
{
    QFile f(qmlPath);
    if (!f.open(QIODevice::ReadOnly))
        return QString();

    // Leading letter skips a quoted import, which is a relative file rather
    // than a module.
    static const QRegularExpression re(QStringLiteral("(?m)^\\s*import\\s+([A-Za-z][\\w.]*)"));
    auto mit = re.globalMatch(QString::fromUtf8(f.readAll()));
    while (mit.hasNext()) {
        const QString uri = mit.next().captured(1);
        if (!moduleAvailable(uri))
            return uri;
    }
    return QString();
}

bool WatchfaceQmlProbe::hasSettings(const QString &name) const
{
    const auto it = m_hasSettings.constFind(name);
    if (it != m_hasSettings.constEnd())
        return it.value();

    QString path = kStockDir + name + QStringLiteral(".qml");
    if (!QFile::exists(path))
        path = WatchfaceHelper::instance()->userWatchfacePath() + name + QStringLiteral(".qml");

    bool has = false;
    QFile f(path);
    if (f.open(QIODevice::ReadOnly)) {
        // The arc convention: "property Component settingsPage" on the root.
        static const QRegularExpression re(
            QStringLiteral("(?m)^\\s*(?:readonly\\s+)?property\\s+\\w+\\s+settingsPage\\b"));
        has = re.match(QString::fromUtf8(f.readAll())).hasMatch();
    }
    m_hasSettings.insert(name, has);
    return has;
}

void WatchfaceQmlProbe::forget(const QString &name)
{
    m_hasSettings.remove(name);
}
