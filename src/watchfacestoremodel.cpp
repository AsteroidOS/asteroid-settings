/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "watchfacestoremodel.h"
#include "watchfacecatalog.h"
#include "watchfacehelper.h"
#include "watchfaceinstaller.h"
#include "watchfacepreviews.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSet>
#include <QTimer>
#include <QUrl>

namespace {
const QString kRawBase = QStringLiteral(
    "https://raw.githubusercontent.com/AsteroidOS/unofficial-watchfaces/master/");
const QString kFacesSub = QStringLiteral("/usr/share/asteroid-launcher/");

// Stock faces shipped with the launcher. Listed as installed=true, stock=true
// so they appear in the same section as community installs.
const QString kStockDir     = QStringLiteral("/usr/share/asteroid-launcher/watchfaces/");
const QString kStockUrlBase = QStringLiteral("file:///usr/share/asteroid-launcher/watchfaces/");
} // namespace


WatchfaceStoreModel::WatchfaceStoreModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_nam(new QNetworkAccessManager(this))
    , m_catalog(new WatchfaceCatalog(m_nam, this))
    , m_installer(new WatchfaceInstaller(m_nam, this))
    , m_previews(new WatchfacePreviews(m_nam, this))
{
    connect(m_installer, &WatchfaceInstaller::progress, this, &WatchfaceStoreModel::onInstallProgress);
    connect(m_installer, &WatchfaceInstaller::finished, this, &WatchfaceStoreModel::onInstallFinished);
    // The catalog owns reachability and the name list; the rows are this
    // model's answer to them.
    connect(m_catalog, &WatchfaceCatalog::namesChanged, this,
            [this]() { rebuildFrom(m_catalog->names()); });
    connect(m_catalog, &WatchfaceCatalog::loadingChanged, this, &WatchfaceStoreModel::loadingChanged);
    connect(m_catalog, &WatchfaceCatalog::hasCatalogChanged, this, &WatchfaceStoreModel::hasCatalogChanged);
    connect(m_catalog, &WatchfaceCatalog::onlineChanged, this, [this]() {
        emit onlineChanged();
        // Catalog rows exist only while online, so a connectivity flip reveals
        // or hides them. Before "get more" there are none to rebuild.
        if (m_browseActive)
            rebuildFrom(m_catalog->names());
    });

    // A finished download resolves to a file that did not exist before, so the
    // row has to redraw. Which row that is is the model's business, not the
    // resolver's.
    connect(m_previews, &WatchfacePreviews::previewReady, this, [this](const QString &name) {
        const int row = indexOfName(name);
        if (row >= 0)
            updateEntry(row, { PreviewRole });
    });

    // Only what the user already has, from two directory scans. The catalog
    // costs are deferred to refresh().
    rebuildFrom(QStringList());

    // A face copied in or removed by any means shows up live. Created if
    // absent: a watch on a missing path is silently dropped.
    const QString wfDir = WatchfaceHelper::instance()->userWatchfacePath();
    QDir().mkpath(wfDir);
    m_dirWatcher = new QFileSystemWatcher(this);
    m_dirWatcher->addPath(wfDir);
    // Activation rewrites files here, so an undebounced watcher fires
    // mid-rewrite and resets the list under the user's fingers.
    m_dirDebounce = new QTimer(this);
    m_dirDebounce->setSingleShot(true);
    m_dirDebounce->setInterval(500);
    connect(m_dirDebounce, &QTimer::timeout, this, &WatchfaceStoreModel::rebuildFromCatalogAndDisk);
    connect(m_dirWatcher, &QFileSystemWatcher::directoryChanged, this, [this, wfDir]() {
        // Some tools replace the directory atomically and drop the watch; re-add.
        if (!m_dirWatcher->directories().contains(wfDir) && QDir(wfDir).exists())
            m_dirWatcher->addPath(wfDir);
        m_dirDebounce->start();
    });

    // Watch the launcher's preview folder (and its per-size subfolders) so a
    // preview the launcher grabs when a face is activated shows up on its tile
    // live, without re-opening the store.
    const QString previewRoot = wfDir.left(wfDir.lastIndexOf(QStringLiteral("watchfaces/")))
        + QStringLiteral("watchfaces-preview/");
    QDir().mkpath(previewRoot);
    m_previewWatcher = new QFileSystemWatcher(this);
    auto watchPreviewDirs = [this, previewRoot]() {
        m_previewWatcher->addPath(previewRoot);
        const QStringList subs = QDir(previewRoot).entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QString &d : subs)
            m_previewWatcher->addPath(previewRoot + d);
    };
    watchPreviewDirs();
    // Atomic writes fire the watcher twice per save, so settle before
    // re-resolving. Unchanged rows keep their URL and do not reload.
    m_previewDebounce = new QTimer(this);
    m_previewDebounce->setSingleShot(true);
    m_previewDebounce->setInterval(300);
    connect(m_previewDebounce, &QTimer::timeout, this, [this, watchPreviewDirs]() {
        watchPreviewDirs(); // a new <size>/ folder may have just appeared
        m_previews->forgetAll();
        if (!m_entries.isEmpty())
            emit dataChanged(index(0), index(m_entries.size() - 1), { PreviewRole });
    });
    connect(m_previewWatcher, &QFileSystemWatcher::directoryChanged,
            m_previewDebounce, qOverload<>(&QTimer::start));
}

// ── QAbstractListModel ──────────────────────────────────────────────────────

int WatchfaceStoreModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_entries.size();
}

QVariant WatchfaceStoreModel::data(const QModelIndex &index, int role) const
{
    if (index.row() < 0 || index.row() >= m_entries.size())
        return {};
    const Entry &e = m_entries.at(index.row());
    switch (role) {
    case NameRole:        return e.name;
    case InstalledRole:   return e.installed;
    case ActiveRole:      return m_activeWatchface == activationValue(e.name);
    case PreviewRole: {
        const QString p = m_previews->pathFor(e.name);
        if (!QFile::exists(p))
            return QString();
        // mtime in the query: an unchanged source URL is never refetched, so a
        // regenerated preview at the same path would not show.
        return p + QStringLiteral("?") + QString::number(QFileInfo(p).lastModified().toMSecsSinceEpoch());
    }
    case DownloadingRole: return e.downloading;
    case ProgressRole:    return e.progress;
    case FailedRole:      return e.failed;
    case StockRole:       return e.stock;
    case MissingModuleRole:
        // Lazily, not at rebuild: the model is constructed before an engine
        // exists, and probing without one reports every module present.
        if (e.installed && !e.moduleChecked) {
            Entry &me = const_cast<Entry &>(e);
            m_probe.ensureEngine(qmlEngine(this));
            me.missingModule = m_probe.firstUnmetImport(
                WatchfaceHelper::instance()->userWatchfacePath() + e.name + QStringLiteral(".qml"));
            me.moduleChecked = true;
        }
        return e.missingModule;
    }
    return {};
}

QHash<int, QByteArray> WatchfaceStoreModel::roleNames() const
{
    return {
        { NameRole,        "name" },
        { InstalledRole,   "installed" },
        { ActiveRole,      "active" },
        { PreviewRole,     "preview" },
        { DownloadingRole, "downloading" },
        { ProgressRole,    "progress" },
        { FailedRole,      "failed" },
        { StockRole,       "stock" },
        { MissingModuleRole, "missingModule" },
    };
}

// ── Properties ──────────────────────────────────────────────────────────────

QString WatchfaceStoreModel::activeWatchface() const { return m_activeWatchface; }

void WatchfaceStoreModel::setActiveWatchface(const QString &name)
{
    if (m_activeWatchface == name)
        return;
    m_activeWatchface = name;
    emit activeWatchfaceChanged();
    if (!m_entries.isEmpty())
        emit dataChanged(index(0), index(m_entries.size() - 1), { ActiveRole });
}

bool WatchfaceStoreModel::online()         const { return m_catalog->online(); }
bool WatchfaceStoreModel::loading()        const { return m_catalog->loading(); }
bool WatchfaceStoreModel::hasCatalog()     const { return m_catalog->hasCatalog(); }
bool WatchfaceStoreModel::browseActive()   const { return m_browseActive; }
int  WatchfaceStoreModel::previewSize()    const { return m_previews->previewSize(); }

void WatchfaceStoreModel::setPreviewSize(int px)
{
    if (m_previews->previewSize() == px)
        return;
    m_previews->setPreviewSize(px); // drops its memo, resolution is size dependent
    emit previewSizeChanged();
    if (!m_entries.isEmpty())
        emit dataChanged(index(0), index(m_entries.size() - 1), { PreviewRole });
}

void WatchfaceStoreModel::setQmlEngine(QQmlEngine *engine)
{
    // qmlEngine(this) is the fallback the singleton needs: it is constructed
    // before the factory hands an engine over, and an import probe with no
    // engine would report every module present.
    m_probe.setQmlEngine(engine ? engine : qmlEngine(this));
}

QString WatchfaceStoreModel::userWallpaperPath() const
{
    // file:// URL of the user asset root's wallpaper folder, the same location
    // install() delivers a watchface's bundled wallpaper into.
    return WatchfaceHelper::instance()->userAssetPath() + QStringLiteral("wallpapers/");
}


// ── List building ───────────────────────────────────────────────────────────
//
// Fetching and caching the repository listings is WatchfaceCatalog's job. What
// stays here is turning a name list plus what is on disk into rows.

void WatchfaceStoreModel::refresh()
{
    // Opening the gate shows the cached rows at once; the conditional fetches
    // revalidate behind them.
    if (!m_browseActive) {
        m_browseActive = true;
        emit browseActiveChanged();
    }
    m_catalog->loadCached();
    m_catalog->probeOnline();
    m_catalog->fetch();
}

void WatchfaceStoreModel::probe()
{
    m_catalog->probeOnline();
}

QStringList WatchfaceStoreModel::installedWatchfaceNames() const
{
    // Top-level *.qml only: a face is its lowercase frontend file, and a
    // multi-design face keeps its variants in a <name>/ subfolder that this
    // non-recursive listing skips, so components never list as bogus faces.
    const QDir dir(WatchfaceHelper::instance()->userWatchfacePath());
    QStringList out;
    for (const QString &f : dir.entryList({ QStringLiteral("*.qml") }, QDir::Files))
        out.append(f.left(f.size() - 4)); // strip ".qml"
    return out;
}

void WatchfaceStoreModel::rebuildFromCatalogAndDisk()
{
    // The watcher also fires when activation merely touches a .qml, so rebuild
    // only when the installed set really changed. During an install the disk and
    // the rows legitimately disagree until the last file lands, so wait it out.
    if (m_installer->busy()) {
        m_dirDebounce->start();
        return;
    }

    const QStringList disk = installedWatchfaceNames();
    QSet<QString> now(disk.cbegin(), disk.cend());
    QSet<QString> have;
    for (const Entry &e : m_entries)
        if (e.installed && !e.stock)
            have.insert(e.name);
    if (now == have) {
        m_pendingDiskSet.clear();
        return;
    }
    // Confirm the same changed set twice: a single read can land in the window
    // where activation has a .qml renamed away, which would reset the list twice.
    if (now != m_pendingDiskSet) {
        m_pendingDiskSet = now;
        m_dirDebounce->start();
        return;
    }
    m_pendingDiskSet.clear();
    rebuildFrom(m_catalog->names());
}

void WatchfaceStoreModel::rebuildFrom(const QStringList &names)
{
    beginResetModel();
    m_entries.clear();

    // Stock faces shipped in the system dir lead the list: always present,
    // always installed. The "installed" section shows them alongside the
    // community faces the user has installed.
    QStringList seen;
    const QStringList stockFiles =
        QDir(kStockDir).entryList({ QStringLiteral("*.qml") }, QDir::Files, QDir::Name);
    for (const QString &f : stockFiles) {
        Entry e;
        e.name      = f.left(f.size() - 4); // strip ".qml"
        e.installed = true;
        e.stock     = true;
        seen.append(e.name);
        m_entries.append(e);
    }

    // Community section: the catalog's available faces unioned with every face
    // in the user folder, so a face installed by any means lists even when the
    // catalog does not carry it. Sorted alphabetically, below the stock faces.
    const QStringList tree = m_catalog->treePaths();
    QStringList community = names;
    for (const QString &n : installedWatchfaceNames())
        if (!community.contains(n))
            community.append(n);
    community.sort();
    for (const QString &n : community) {
        if (seen.contains(n) || WatchfaceCatalog::isSkippedDir(n))
            continue;
        const bool installed = isInstalledOnDisk(n);
        // Un-installed catalog faces list only while the user is browsing AND
        // online: before "get more" they are not asked for, and offline a
        // catalog face cannot be downloaded — tapping it would move the
        // wallpaper for the peek yet never install.
        if (!installed && (!m_browseActive || !m_catalog->online()))
            continue;
        // Skip catalog-only names that are not watchfaces (no <name>.qml in the
        // tree), such as shared component dirs, so they never list as a blank
        // tile. An installed face always lists, including a local push the
        // online tree does not carry.
        if (!installed
            && !tree.isEmpty()
            && !tree.contains(n + kFacesSub + QStringLiteral("watchfaces/") + n + QStringLiteral(".qml")))
            continue;
        Entry e;
        e.name      = n;
        e.installed = installed;
        // missingModule is probed lazily in data(), once an engine is attached.
        m_entries.append(e);
    }

    endResetModel();
}

int WatchfaceStoreModel::indexOfName(const QString &name) const
{
    for (int i = 0; i < m_entries.size(); ++i)
        if (m_entries.at(i).name == name)
            return i;
    return -1;
}

void WatchfaceStoreModel::updateEntry(int row, const QList<int> &roles)
{
    if (row < 0 || row >= m_entries.size())
        return;
    emit dataChanged(index(row), index(row), roles);
}

bool WatchfaceStoreModel::isInstalledOnDisk(const QString &name) const
{
    return QFile::exists(WatchfaceHelper::instance()->userWatchfacePath()
                         + name + QStringLiteral(".qml"));
}

// ── Preview and QML probing ─────────────────────────────────────────────────
//
// Resolution, download and QML inspection live in WatchfacePreviews and
// WatchfaceQmlProbe. What stays here is the QML-facing surface and the row
// bookkeeping, which is the model's business.

void WatchfaceStoreModel::requestPreview(const QString &name)
{
    m_previews->request(name);
}

QString WatchfaceStoreModel::watchfaceUrl(const QString &name) const
{
    return activationValue(name);
}

bool WatchfaceStoreModel::faceHasSettings(const QString &name) const
{
    return m_probe.hasSettings(name);
}

// ── Install / remove ────────────────────────────────────────────────────────

QString WatchfaceStoreModel::activationValue(const QString &name) const
{
    // Stock faces activate from the system dir; community faces from the user
    // asset dir where install() places them. The row already knows which side
    // a face came from, so the hot path (ActiveRole for every row on each
    // active-face change) needs no filesystem check; the stat fallback only
    // runs for a name that is not in the model.
    const int row = indexOfName(name);
    const bool stock = row >= 0 ? m_entries.at(row).stock
                                : QFile::exists(kStockDir + name + QStringLiteral(".qml"));
    if (stock)
        return kStockUrlBase + name + QStringLiteral(".qml");
    return WatchfaceHelper::instance()->userAssetPath()
        + QStringLiteral("watchfaces/") + name + QStringLiteral(".qml");
}

void WatchfaceStoreModel::install(const QString &name)
{
    if (m_installer->isInstalling(name))
        return;
    const int row = indexOfName(name);
    if (row < 0)
        return;

    m_entries[row].downloading = true;
    m_entries[row].failed = false;
    m_entries[row].progress = 0.0;
    updateEntry(row, { DownloadingRole, FailedRole, ProgressRole });

    m_installer->start(name, m_catalog->treePaths(), userWallpaperPath());
}

void WatchfaceStoreModel::onInstallProgress(const QString &name, qreal fraction)
{
    const int row = indexOfName(name);
    if (row < 0)
        return;
    m_entries[row].progress = fraction;
    updateEntry(row, { ProgressRole });
}

void WatchfaceStoreModel::onInstallFinished(const QString &name, bool success,
                                            const QString &wallpaper)
{
    // The new QML is fresh in the user folder. Drop this app's component cache
    // so its live preview re-reads the directory instead of failing with
    // "File name case mismatch".
    QString unmet;
    if (success) {
        if (QQmlEngine *engine = qmlEngine(this)) {
            engine->clearComponentCache();
            m_probe.ensureEngine(engine);
        }
        // A face importing a module missing here would render blank. Keep it
        // installed but greyed, and never activate it.
        unmet = m_probe.firstUnmetImport(
            WatchfaceHelper::instance()->userWatchfacePath() + name + QStringLiteral(".qml"));
    }
    const bool available = success && unmet.isEmpty();

    const int row = indexOfName(name);
    if (row >= 0) {
        m_entries[row].downloading = false;
        m_entries[row].progress = success ? 1.0 : 0.0;
        if (success)
            m_entries[row].installed = true;
        m_entries[row].failed = !success;
        m_entries[row].missingModule = unmet;
        m_entries[row].moduleChecked = success; // probed here; data() need not re-probe
        m_probe.forget(name); // fresh QML may have gained or lost a settingsPage
        updateEntry(row, { DownloadingRole, ProgressRole, InstalledRole, FailedRole, ActiveRole, MissingModuleRole });
    }

    if (available) {
        // Force the bundled wallpaper once, on this install only: this never
        // runs on re-activation, so the user's later choice is respected.
        if (!wallpaper.isEmpty())
            emit wallpaperForced(wallpaper);
        // QML routes this through its activation-delay timer, shared with manual
        // selection, so a just-installed face never overwrites one the user taps
        // immediately afterwards.
        emit activated(activationValue(name));
    } else if (!success) {
        emit installFailed(name);
    }
    // Installed but unavailable (unmet import): stays greyed, not activated.
}

void WatchfaceStoreModel::remove(const QString &name)
{
    const bool wasActive = m_activeWatchface == activationValue(name);

    WatchfaceHelper::instance()->removeWatchface(name);
    m_probe.forget(name);
    m_previews->forget(name);
    const int row = indexOfName(name);
    if (row >= 0) {
        m_entries[row].installed = false;
        updateEntry(row, { InstalledRole, ActiveRole });
    }

    // Removing the face that is currently shown would leave the homescreen
    // blank: the key still points at a file that is now gone. Hand activation
    // to the nearest face still installed, preferring the one above, which is
    // the neighbour the user was just looking at.
    if (wasActive && row >= 0) {
        const int next = nearestInstalled(row);
        if (next >= 0)
            emit activated(activationValue(m_entries.at(next).name));
    }

}

int WatchfaceStoreModel::nearestInstalled(int row) const
{
    for (int i = row - 1; i >= 0; --i)
        if (m_entries.at(i).installed)
            return i;
    for (int i = row + 1; i < m_entries.size(); ++i)
        if (m_entries.at(i).installed)
            return i;
    return -1;
}

