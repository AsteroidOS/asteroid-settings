/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "watchfacehelper.h"

#include <QDir>
#include <QFile>
#include <QStandardPaths>

WatchfaceHelper::WatchfaceHelper(QObject *parent)
    : QObject(parent)
{
}

WatchfaceHelper *WatchfaceHelper::instance()
{
    static WatchfaceHelper self;
    return &self;
}

// ── Paths ───────────────────────────────────────────────────────────────────

QString WatchfaceHelper::userDataPath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
        + QStringLiteral("/asteroid-launcher/");
}

QString WatchfaceHelper::userWatchfacePath() const
{
    return userDataPath() + QStringLiteral("watchfaces/");
}

QString WatchfaceHelper::userAssetPath() const
{
    return QStringLiteral("file://") + userDataPath();
}

QString WatchfaceHelper::userFontsPath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::HomeLocation)
        + QStringLiteral("/.fonts/");
}

QString WatchfaceHelper::cachePath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation)
        + QStringLiteral("/asteroid-settings/watchface-store/");
}

// ── Destructive operations ──────────────────────────────────────────────────

void WatchfaceHelper::removeWatchface(const QString &name)
{
    // The name is a bare face name from the catalog or the user folder. Refuse
    // anything that could traverse out of the store's folders or behave as a
    // glob below; every path built here embeds it.
    if (name.isEmpty()
        || name.contains(QLatin1Char('/')) || name.contains(QLatin1Char('\\'))
        || name.contains(QLatin1String("..")) || name.contains(QLatin1Char('*'))
        || name.contains(QLatin1Char('?')) || name.contains(QLatin1Char('[')))
        return;

    QFile::remove(userWatchfacePath() + name + QStringLiteral(".qml"));
    // A multi-design face keeps its variant components in a <name>/ subfolder.
    QDir(userWatchfacePath() + name).removeRecursively();

    // Launcher-grabbed previews live under watchfaces-preview/<size>/, one
    // folder per size the launcher chose to render. Enumerate the folders
    // rather than assuming a fixed size set, and cover both the webp the
    // renderer writes and any older png.
    const QString previewRoot = userDataPath() + QStringLiteral("watchfaces-preview/");
    const QStringList sizeDirs = QDir(previewRoot).entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &d : sizeDirs) {
        QFile::remove(previewRoot + d + QLatin1Char('/') + name + QStringLiteral(".webp"));
        QFile::remove(previewRoot + d + QLatin1Char('/') + name + QStringLiteral(".png"));
    }

    // Image assets: a face's own subfolder, plus the flat name-prefixed file
    // convention. The prefix pattern can only over-match if another installed
    // face is literally named "<name>-<suffix>"; the repo has no such pair and
    // the name is validated above, so the simple pattern stays.
    QDir imgDir(userDataPath() + QStringLiteral("watchfaces-img/"));
    QDir(imgDir.filePath(name)).removeRecursively();
    if (imgDir.exists()) {
        const QStringList filters = { name + QStringLiteral("-*"),
                                      name + QStringLiteral(".*") };
        const QStringList files = imgDir.entryList(filters, QDir::Files);
        for (const QString &f : files)
            imgDir.remove(f);
    }
}
