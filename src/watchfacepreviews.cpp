/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "watchfacepreviews.h"
#include "watchfacehelper.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>

#include <limits>

namespace {
const QString kRawBase = QStringLiteral(
    "https://raw.githubusercontent.com/AsteroidOS/unofficial-watchfaces/master/");
const QString kFacesSub     = QStringLiteral("/usr/share/asteroid-launcher/");
const QString kStockPreview = QStringLiteral("/usr/share/asteroid-launcher/watchfaces-preview/");

/*!
 * \internal
 * The preview for \a name under \a root from the size folder closest to
 * \a target.
 *
 * Preview trees are laid out as <root>/<pixel size>/<name><suffix>. Which
 * sizes exist is not known here, and directory order is smallest first, so
 * taking the first hit would scale up past a better fitting neighbour. A
 * non-numeric folder name, and the case of no target yet, fall back to
 * first-hit order.
 */
QString nearestSizedPreview(const QString &root, const QString &name,
                            const QString &suffix, int target)
{
    QString best;
    int bestDelta = std::numeric_limits<int>::max();
    const QStringList sizeDirs = QDir(root).entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &d : sizeDirs) {
        const QString cand = root + d + QLatin1Char('/') + name + suffix;
        if (!QFile::exists(cand))
            continue;
        bool isNumber = false;
        const int px = d.toInt(&isNumber);
        const bool comparable = isNumber && target > 0;
        if (best.isEmpty()) {
            best = cand;
            bestDelta = comparable ? qAbs(px - target) : std::numeric_limits<int>::max();
            continue;
        }
        if (!comparable)
            continue;
        const int delta = qAbs(px - target);
        if (delta < bestDelta) {
            bestDelta = delta;
            best = cand;
        }
    }
    return best;
}
} // namespace

WatchfacePreviews::WatchfacePreviews(QNetworkAccessManager *nam, QObject *parent)
    : QObject(parent)
    , m_nam(nam)
{
}

void WatchfacePreviews::setPreviewSize(int px)
{
    if (m_previewSize == px)
        return;
    m_previewSize = px;
    forgetAll(); // resolution is size dependent
}

int WatchfacePreviews::previewSize() const
{
    return m_previewSize;
}

QString WatchfacePreviews::galleryCachePathFor(const QString &name) const
{
    // Created at download time, not here: this runs on lookup paths too.
    return WatchfaceHelper::instance()->cachePath()
        + QStringLiteral("thumbnails/") + name + QStringLiteral(".webp");
}

QString WatchfacePreviews::pathFor(const QString &name) const
{
    const auto it = m_paths.constFind(name);
    if (it != m_paths.constEnd())
        return it.value();

    const QString previewRoot = WatchfaceHelper::instance()->userDataPath()
        + QStringLiteral("watchfaces-preview/");

    // What the launcher grabbed on this device, at whatever size it chose.
    QString resolved = nearestSizedPreview(previewRoot, name, QStringLiteral(".webp"), m_previewSize);

    // The transparent master a face ships, preferred over the flat gallery
    // thumbnail so the tile draws on the live background.
    if (resolved.isEmpty()) {
        const QString shipped = previewRoot + name + QStringLiteral("-full.webp");
        if (QFile::exists(shipped))
            resolved = shipped;
    }
    if (resolved.isEmpty()) {
        const QString stockMaster = kStockPreview + name + QStringLiteral("-full.webp");
        if (QFile::exists(stockMaster))
            resolved = stockMaster;
    }

    // The older stock layout, one opaque PNG per size, for a launcher that
    // predates the master set.
    if (resolved.isEmpty())
        resolved = nearestSizedPreview(kStockPreview, name, QStringLiteral(".png"), m_previewSize);

    if (resolved.isEmpty()) {
        const QString gallery = galleryCachePathFor(name);
        if (QFile::exists(gallery))
            resolved = gallery;
    }

    m_paths.insert(name, resolved); // misses cached too; forget() reopens them
    return resolved;
}

void WatchfacePreviews::request(const QString &name)
{
    if (!pathFor(name).isEmpty())
        return;
    if (m_queue.contains(name))
        return;
    m_queue.append(name);
    startNext();
}

void WatchfacePreviews::forget(const QString &name)
{
    m_paths.remove(name);
}

void WatchfacePreviews::forgetAll()
{
    m_paths.clear();
}

void WatchfacePreviews::startNext()
{
    if (m_busy || m_queue.isEmpty())
        return;
    const QString name = m_queue.takeFirst();
    const QString dest = galleryCachePathFor(name);
    if (QFile::exists(dest)) { // cached meanwhile
        startNext();
        return;
    }
    m_busy = true;

    const QString masterUrl = kRawBase + name + kFacesSub
        + QStringLiteral("watchfaces-preview/") + name + QStringLiteral("-full.webp");
    const QString thumbUrl = kRawBase + QStringLiteral(".thumbnails/") + name
        + QStringLiteral(".webp");
    QDir().mkpath(QFileInfo(dest).absolutePath());

    // A 404 returns a short text body, not a RIFF image, so cache on the magic
    // rather than on the status. A missing preview is never fatal.
    auto cacheIfImage = [this, dest, name](QNetworkReply *r) -> bool {
        if (r->error() != QNetworkReply::NoError)
            return false;
        const QByteArray body = r->readAll();
        if (!body.startsWith("RIFF"))
            return false;
        QFile f(dest);
        if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
            f.write(body);
            f.close();
            m_paths.remove(name); // the cache dir is not watched
            Q_EMIT previewReady(name);
        }
        return true;
    };

    QNetworkReply *reply = m_nam->get(QNetworkRequest(QUrl(masterUrl)));
    connect(reply, &QNetworkReply::finished, this, [this, reply, thumbUrl, cacheIfImage]() {
        const bool got = cacheIfImage(reply);
        reply->deleteLater();
        if (got) {
            m_busy = false;
            startNext();
            return;
        }
        // No master shipped: fall back to the gallery thumbnail.
        QNetworkReply *fb = m_nam->get(QNetworkRequest(QUrl(thumbUrl)));
        connect(fb, &QNetworkReply::finished, this, [this, fb, cacheIfImage]() {
            cacheIfImage(fb);
            fb->deleteLater();
            m_busy = false;
            startNext();
        });
    });
}
