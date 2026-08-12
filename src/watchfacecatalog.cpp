/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "watchfacecatalog.h"
#include "watchfacehelper.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>

namespace {
const QString kApiBase = QStringLiteral(
    "https://api.github.com/repos/AsteroidOS/unofficial-watchfaces/contents/");
const QString kRawBase = QStringLiteral(
    "https://raw.githubusercontent.com/AsteroidOS/unofficial-watchfaces/master/");
const QString kProbeUrl = kRawBase + QStringLiteral("README.md");
const QString kTreeApi = QStringLiteral(
    "https://api.github.com/repos/AsteroidOS/unofficial-watchfaces/git/trees/master?recursive=1");

bool writeFile(const QString &path, const QByteArray &data)
{
    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    f.write(data);
    f.close();
    return true;
}

QByteArray readTrimmed(const QString &path)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly))
        return {};
    return f.readAll().trimmed();
}
} // namespace

WatchfaceCatalog::WatchfaceCatalog(QNetworkAccessManager *nam, QObject *parent)
    : QObject(parent)
    , m_nam(nam)
{
}

bool WatchfaceCatalog::online() const  { return m_online; }
bool WatchfaceCatalog::loading() const { return m_loading; }
bool WatchfaceCatalog::hasCatalog() const { return QFile::exists(catalogCachePath()); }
QStringList WatchfaceCatalog::names() const { return m_names; }

bool WatchfaceCatalog::isSkippedDir(const QString &name)
{
    return name.isEmpty()
        || name.startsWith(QLatin1Char('.'))
        || name == QLatin1String("tests")
        || name == QLatin1String("fake-components");
}

void WatchfaceCatalog::setOnline(bool v)
{
    if (m_online == v)
        return;
    m_online = v;
    Q_EMIT onlineChanged();
}

void WatchfaceCatalog::setLoading(bool v)
{
    if (m_loading == v)
        return;
    m_loading = v;
    Q_EMIT loadingChanged();
}

void WatchfaceCatalog::probeOnline()
{
    QNetworkReply *reply = m_nam->head(QNetworkRequest(QUrl(kProbeUrl)));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        setOnline(reply->error() == QNetworkReply::NoError);
        reply->deleteLater();
    });
}

void WatchfaceCatalog::loadCached()
{
    QStringList names;
    QFile f(catalogCachePath());
    if (f.open(QIODevice::ReadOnly))
        names = parseCatalog(f.readAll());
    m_names = names;
    Q_EMIT namesChanged();
}

void WatchfaceCatalog::fetch()
{
    fetchCatalog();
    fetchTree();
}

void WatchfaceCatalog::fetchCatalog()
{
    setLoading(true);
    QNetworkRequest req{ QUrl(kApiBase) };
    const QByteArray etag = readCachedEtag();
    if (!etag.isEmpty())
        req.setRawHeader("If-None-Match", etag);

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        setLoading(false);
        const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (reply->error() == QNetworkReply::NoError && status == 200) {
            setOnline(true);
            const QByteArray body = reply->readAll();
            writeCatalogCache(body, reply->rawHeader("ETag"));
            m_names = parseCatalog(body);
            Q_EMIT namesChanged();
        } else if (status == 304) {
            setOnline(true); // unchanged, and the cache is already displayed
        }
        // A failure is not proof of being offline: a rate-limit 403 still shows
        // the network is up, and probeOnline() owns that state. Leaving it alone
        // keeps the cached list usable instead of greying the action.
        reply->deleteLater();
    });
}

void WatchfaceCatalog::fetchTree()
{
    QNetworkRequest req{ QUrl(kTreeApi) };
    const QByteArray etag = readTreeEtag();
    if (!etag.isEmpty())
        req.setRawHeader("If-None-Match", etag);

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (reply->error() == QNetworkReply::NoError && status == 200)
            writeTreeCache(parseTree(reply->readAll()), reply->rawHeader("ETag"));
        // 304 or any error: keep the cached tree.
        reply->deleteLater();
    });
}

QStringList WatchfaceCatalog::parseCatalog(const QByteArray &body) const
{
    QStringList names;
    const QJsonDocument doc = QJsonDocument::fromJson(body);
    if (!doc.isArray())
        return names;
    for (const QJsonValue &v : doc.array()) {
        const QJsonObject o = v.toObject();
        if (o.value(QStringLiteral("type")).toString() != QLatin1String("dir"))
            continue;
        const QString name = o.value(QStringLiteral("name")).toString();
        if (isSkippedDir(name))
            continue;
        names.append(name);
    }
    return names;
}

QStringList WatchfaceCatalog::parseTree(const QByteArray &body) const
{
    QStringList paths;
    const QJsonObject root = QJsonDocument::fromJson(body).object();
    for (const QJsonValue &v : root.value(QStringLiteral("tree")).toArray()) {
        const QJsonObject o = v.toObject();
        if (o.value(QStringLiteral("type")).toString() == QLatin1String("blob"))
            paths.append(o.value(QStringLiteral("path")).toString());
    }
    return paths;
}

QString WatchfaceCatalog::catalogCachePath() const
{
    return WatchfaceHelper::instance()->cachePath() + QStringLiteral("catalog.json");
}

QString WatchfaceCatalog::treeCachePath() const
{
    return WatchfaceHelper::instance()->cachePath() + QStringLiteral("tree.txt");
}

QByteArray WatchfaceCatalog::readCachedEtag() const
{
    return readTrimmed(WatchfaceHelper::instance()->cachePath()
                       + QStringLiteral("catalog.etag"));
}

QByteArray WatchfaceCatalog::readTreeEtag() const
{
    return readTrimmed(WatchfaceHelper::instance()->cachePath() + QStringLiteral("tree.etag"));
}

void WatchfaceCatalog::writeCatalogCache(const QByteArray &body, const QByteArray &etag)
{
    const QString base = WatchfaceHelper::instance()->cachePath();
    QDir().mkpath(base);
    writeFile(catalogCachePath(), body);
    writeFile(base + QStringLiteral("catalog.etag"), etag);
    Q_EMIT hasCatalogChanged(); // first fetch changes the store action label
}

void WatchfaceCatalog::writeTreeCache(const QStringList &paths, const QByteArray &etag)
{
    const QString base = WatchfaceHelper::instance()->cachePath();
    QDir().mkpath(base);
    writeFile(treeCachePath(), paths.join(QLatin1Char('\n')).toUtf8());
    writeFile(base + QStringLiteral("tree.etag"), etag);
}

QStringList WatchfaceCatalog::treePaths() const
{
    QFile f(treeCachePath());
    if (!f.open(QIODevice::ReadOnly))
        return {};
    return QString::fromUtf8(f.readAll()).split(QLatin1Char('\n'), Qt::SkipEmptyParts);
}
