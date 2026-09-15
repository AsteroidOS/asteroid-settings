/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "watchfaceinstaller.h"
#include "watchfacehelper.h"

#include <QDir>
#include <QFileInfo>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSaveFile>
#include <QUrl>

namespace {
const QString kRawBase = QStringLiteral(
    "https://raw.githubusercontent.com/AsteroidOS/unofficial-watchfaces/master/");
const QString kFacesSub = QStringLiteral("/usr/share/asteroid-launcher/");
}

//! One in-flight install: files still downloading and counters for progress.
struct WatchfaceInstaller::Transaction {
    QString name;
    QString wallpaper; //!< destination URL of the bundled wallpaper, if any
    int  pending = 0;
    int  total   = 0;
    int  done    = 0;
    bool failed  = false;
};

WatchfaceInstaller::WatchfaceInstaller(QNetworkAccessManager *nam, QObject *parent)
    : QObject(parent)
    , m_nam(nam)
{
}

WatchfaceInstaller::~WatchfaceInstaller()
{
    qDeleteAll(m_transactions);
}

bool WatchfaceInstaller::isInstalling(const QString &name) const
{
    return m_transactions.contains(name);
}

bool WatchfaceInstaller::busy() const
{
    return !m_transactions.isEmpty();
}

void WatchfaceInstaller::start(const QString &name, const QStringList &tree,
                               const QString &wallpaperDestBase)
{
    if (m_transactions.contains(name))
        return;

    Transaction *tx = new Transaction;
    tx->name = name;
    m_transactions.insert(name, tx);

    WatchfaceHelper *h = WatchfaceHelper::instance();
    const QString userBase = h->userWatchfacePath();
    const QString userRoot = h->userDataPath();

    // The QML is the essential file: its failure fails the install. No preview
    // is fetched; the launcher grabs one from its own render on activation.
    queueFile(tx, kRawBase + name + kFacesSub + QStringLiteral("watchfaces/") + name
                  + QStringLiteral(".qml"),
              userBase + name + QStringLiteral(".qml"), true);

    const QString wallRepoDir = name + kFacesSub + QStringLiteral("wallpapers/full/");
    // Sibling files in the face's own dir: shared scripts, extra assets.
    queueTreeDir(tx, tree, name + kFacesSub + QStringLiteral("watchfaces/"), userBase,
                 name + QStringLiteral(".qml"));
    queueTreeDir(tx, tree, name + kFacesSub + QStringLiteral("watchfaces-img/"),
                 userRoot + QStringLiteral("watchfaces-img/"));
    queueTreeDir(tx, tree, wallRepoDir, userRoot + QStringLiteral("wallpapers/full/"));
    queueTreeDir(tx, tree, name + QStringLiteral("/usr/share/fonts/"), h->userFontsPath());

    // First image directly under the wallpaper dir; licence sidecars are skipped.
    for (const QString &path : tree) {
        if (!path.startsWith(wallRepoDir))
            continue;
        const QString rel = path.mid(wallRepoDir.length());
        if (rel.contains(QLatin1Char('/')))
            continue;
        if (rel.endsWith(QLatin1String(".jpg")) || rel.endsWith(QLatin1String(".png"))
            || rel.endsWith(QLatin1String(".svg"))) {
            tx->wallpaper = wallpaperDestBase + QStringLiteral("full/") + rel;
            break;
        }
    }
}

void WatchfaceInstaller::queueFile(Transaction *tx, const QString &url, const QString &dest,
                                   bool isQml)
{
    tx->pending++;
    tx->total++;
    QDir().mkpath(QFileInfo(dest).absolutePath());

    QNetworkReply *reply = m_nam->get(QNetworkRequest(QUrl(url)));
    connect(reply, &QNetworkReply::finished, this, [this, tx, reply, dest, isQml]() {
        bool ok = reply->error() == QNetworkReply::NoError;
        if (ok) {
            // Temp file + rename, so a failed write cannot leave a truncated
            // face that lists as installed.
            QSaveFile f(dest);
            if (f.open(QIODevice::WriteOnly)) {
                f.write(reply->readAll());
                ok = f.commit();
            } else {
                ok = false;
            }
        }
        if (!ok && isQml)
            tx->failed = true;
        reply->deleteLater();

        tx->pending--;
        tx->done++;
        Q_EMIT progress(tx->name, tx->total ? qreal(tx->done) / tx->total : 0.0);
        maybeFinish(tx);
    });
}

void WatchfaceInstaller::queueTreeDir(Transaction *tx, const QStringList &tree,
                                      const QString &repoDir, const QString &destPrefix,
                                      const QString &skip)
{
    // Synchronous, no network listing, so tx->pending already counts every file
    // before the first reply returns. Nested subpaths are preserved.
    for (const QString &path : tree) {
        if (!path.startsWith(repoDir))
            continue;
        const QString rel = path.mid(repoDir.length());
        if (rel.isEmpty())
            continue;
        // The tree is remote data: refuse a path that would climb out of the
        // destination folder rather than trusting it into a local write.
        if (rel.startsWith(QLatin1Char('/')) || rel.contains(QLatin1String("..")))
            continue;
        if (!skip.isEmpty() && rel == skip)
            continue; // already queued, e.g. the essential QML
        queueFile(tx, kRawBase + path, destPrefix + rel, false);
    }
}

void WatchfaceInstaller::maybeFinish(Transaction *tx)
{
    if (tx->pending != 0)
        return;

    // By value: taking and deleting the transaction frees tx->name, which the
    // signal argument would otherwise dangle on.
    const QString name = tx->name;
    const QString wallpaper = tx->wallpaper;
    const bool success = !tx->failed;
    delete m_transactions.take(name);

    Q_EMIT finished(name, success, wallpaper);
}
