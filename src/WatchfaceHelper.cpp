/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
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

#include "WatchfaceHelper.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QProcess>
#include <QStandardPaths>
#include <QUrl>

static const QStringList PREVIEW_SIZES = {
    QStringLiteral("112"), QStringLiteral("128"),
    QStringLiteral("144"), QStringLiteral("160"), QStringLiteral("182")
};

WatchfaceHelper *WatchfaceHelper::s_instance = nullptr;

WatchfaceHelper::WatchfaceHelper(QObject *parent)
: QObject(parent)
, m_nam(new QNetworkAccessManager(this))
{
    s_instance = this;
    // Ensure user watchface and cache directories exist on first run
    QDir().mkpath(userWatchfacePath());
    QDir().mkpath(cachePath());
}

WatchfaceHelper *WatchfaceHelper::instance()
{
    if (!s_instance)
        s_instance = new WatchfaceHelper();
    return s_instance;
}

QObject *WatchfaceHelper::qmlInstance(QQmlEngine *, QJSEngine *)
{
    return instance();
}

// ── Path helpers ──────────────────────────────────────────────────────────────

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
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
    + QStringLiteral("/watchface-store/");
}

bool WatchfaceHelper::isPathAllowed(const QString &path) const
{
    if (path.startsWith(cachePath()))       return true;
    if (path.startsWith(userDataPath()))    return true;
    if (path.startsWith(userFontsPath()))   return true;
    return false;
}

// ── Public API ────────────────────────────────────────────────────────────────

void WatchfaceHelper::downloadFile(const QString &url, const QString &destPath)
{
    if (!isPathAllowed(destPath)) {
        qWarning() << "WatchfaceHelper: blocked write attempt to" << destPath;
        emit downloadComplete(destPath, false);
        return;
    }
    
    QUrl qurl(url);
    QNetworkRequest req(qurl);
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                     QNetworkRequest::NoLessSafeRedirectPolicy);
    QNetworkReply *reply = m_nam->get(req);
    
    connect(reply, &QNetworkReply::downloadProgress,
            this, [this, destPath](qint64 recv, qint64 total) {
                emit downloadProgress(destPath, recv, total);
            });
    
    connect(reply, &QNetworkReply::finished,
            this, [this, reply, destPath]() {
                reply->deleteLater();
                
                if (reply->error() != QNetworkReply::NoError) {
                    qWarning() << "WatchfaceHelper: download error for"
                    << destPath << ":" << reply->errorString();
                    emit downloadComplete(destPath, false);
                    return;
                }
                
                const QFileInfo fi(destPath);
                if (!QDir().mkpath(fi.absolutePath())) {
                    qWarning() << "WatchfaceHelper: cannot create directory"
                    << fi.absolutePath();
                    emit downloadComplete(destPath, false);
                    return;
                }
                
                QFile file(destPath);
                if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
                    qWarning() << "WatchfaceHelper: cannot open for writing:" << destPath;
                    emit downloadComplete(destPath, false);
                    return;
                }
                
                file.write(reply->readAll());
                file.close();
                emit downloadComplete(destPath, true);
            });
}

bool WatchfaceHelper::mkpath(const QString &dirPath)
{
    return QDir().mkpath(dirPath);
}

bool WatchfaceHelper::removeWatchface(const QString &name)
{
    bool removedQml = false;
    
    const QString qmlPath = userWatchfacePath() + name + QStringLiteral(".qml");
    if (QFile::exists(qmlPath))
        removedQml = QFile::remove(qmlPath);
    
    for (const QString &size : PREVIEW_SIZES) {
        const QString p = userDataPath()
        + QStringLiteral("watchfaces-preview/")
        + size + QStringLiteral("/") + name + QStringLiteral(".png");
        if (QFile::exists(p)) QFile::remove(p);
    }
    
    QDir imgDir(userDataPath() + QStringLiteral("watchface-img/"));
    if (imgDir.exists()) {
        const QStringList filters = {
            name + QStringLiteral("-*"),
            name + QStringLiteral(".*")
        };
        for (const QString &f : imgDir.entryList(filters, QDir::Files))
            imgDir.remove(f);
    }
    
    return removedQml;
}

void WatchfaceHelper::restartSession()
{
    QProcess::execute(QStringLiteral("fc-cache"), {QStringLiteral("-f")});
    QProcess::startDetached(QStringLiteral("systemctl"),
                            {QStringLiteral("--user"), QStringLiteral("restart"), QStringLiteral("asteroid-launcher")});
}

QString WatchfaceHelper::readFile(const QString &path) const
{
    if (!path.startsWith(cachePath())) {
        qWarning() << "WatchfaceHelper: blocked read attempt from" << path;
        return QString();
    }
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return QString();
    return QString::fromUtf8(f.readAll());
}

bool WatchfaceHelper::writeFile(const QString &path, const QString &content)
{
    if (!isPathAllowed(path)) {
        qWarning() << "WatchfaceHelper: blocked write attempt to" << path;
        return false;
    }
    const QFileInfo fi(path);
    QDir().mkpath(fi.absolutePath());
    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text))
        return false;
    f.write(content.toUtf8());
    return true;
}
