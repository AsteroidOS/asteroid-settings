/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef WATCHFACESTOREMODEL_H
#define WATCHFACESTOREMODEL_H

#include "watchfaceqmlprobe.h"

#include <QAbstractListModel>
#include <QFileSystemWatcher>
#include <QList>
#include <QNetworkAccessManager>
#include <QSet>
#include <QString>
#include <QStringList>

class QQmlEngine;
class QTimer;
class WatchfaceCatalog;
class WatchfaceInstaller;
class WatchfacePreviews;

/*!
 * \brief The watchface list QML binds to, with per-face install state.
 *
 * Stock faces, installed community faces and, once the user asks to browse,
 * what the catalog offers. Turns the catalog, the installer, the preview
 * resolver and the QML probe into rows, and owns what their results mean for
 * a row, for activation and for the import gate.
 *
 * The work itself lives elsewhere: WatchfaceCatalog fetches, WatchfaceInstaller
 * downloads, WatchfacePreviews resolves images, WatchfaceQmlProbe reads a
 * face's QML, and WatchfaceHelper is the single source for paths and removal.
 */
class WatchfaceStoreModel : public QAbstractListModel
{
    Q_OBJECT

    //! The active watchface name, bound from QML to /desktop/asteroid/watchface.
    //! Drives the Active role so the current face is marked in the list.
    Q_PROPERTY(QString activeWatchface READ activeWatchface WRITE setActiveWatchface NOTIFY activeWatchfaceChanged)

    //! False when the catalog endpoint is unreachable (offline / no network).
    Q_PROPERTY(bool online READ online NOTIFY onlineChanged)

    //! True while the catalog is being (re)fetched.
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)

    //! True once a catalog has been fetched and cached at least once, so QML
    //! can label the store action "update" rather than "get more".
    Q_PROPERTY(bool hasCatalog READ hasCatalog NOTIFY hasCatalogChanged)

    //! The pixel size a preview is shown at. Supplied by QML because the screen
    //! proportion it comes from (Dims) lives there, so no device-size constant
    //! is carried here. Passed to the preview resolver, which picks the nearest
    //! size folder on disk.
    Q_PROPERTY(int previewSize READ previewSize WRITE setPreviewSize NOTIFY previewSizeChanged)

    //! False until the user explicitly asks to browse the catalog ("get
    //! more"). While false the model lists only stock and installed faces, so
    //! opening the page costs nothing beyond two directory scans; every
    //! catalog cost (cache parse, network refresh, thumbnail downloads and the
    //! delegates for ~80 rows) is deferred to the moment the user asks for it.
    Q_PROPERTY(bool browseActive READ browseActive NOTIFY browseActiveChanged)

public:
    enum Role {
        NameRole = Qt::UserRole + 1, //!< watchface directory name (QString)
        InstalledRole,               //!< present in the user watchface folder (bool)
        ActiveRole,                  //!< equals activeWatchface (bool)
        PreviewRole,                 //!< local cached preview file path, or "" (QString)
        DownloadingRole,             //!< an install is in flight (bool)
        ProgressRole,                //!< install progress 0.0..1.0 (qreal)
        FailedRole,                  //!< last install attempt failed (bool)
        StockRole,                   //!< shipped in the system dir, not the community catalog (bool)
        MissingModuleRole            //!< the unmet import module name, or "" when available (QString)
    };
    Q_ENUM(Role)

    explicit WatchfaceStoreModel(QObject *parent = nullptr);

    // QAbstractListModel
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString activeWatchface() const;
    void    setActiveWatchface(const QString &name);
    bool    online() const;
    bool    loading() const;
    bool    hasCatalog() const;
    bool    browseActive() const;
    int     previewSize() const;
    void    setPreviewSize(int px);

    //! Hand the QML engine to the model. Set once from the singleton factory;
    //! the import-availability probe needs an engine and a singleton is not
    //! attached to one the way a QML-declared object is.
    void setQmlEngine(QQmlEngine *engine);

    /*!
     * \brief The "get more" action: open the catalog and refresh it.
     * Flips browseActive, immediately rebuilds the rows from the cached
     * catalog so the list fills without waiting for the network, then
     * revalidates the catalog and repo tree with conditional requests. An
     * unchanged catalog (304) costs nothing further: the cached rows are
     * already showing. Previews are fetched lazily as rows become visible.
     */
    Q_INVOKABLE void refresh();

    /*!
     * \brief Check reachability of the catalog endpoint without fetching it.
     * Called on page open so the store action reflects the online state; the
     * catalog itself is only fetched when the user taps "get more"/"update".
     */
    Q_INVOKABLE void probe();

    /*!
     * \brief Ensure the preview for a row is cached, fetching it if missing.
     * Called by the delegate when it first needs the image. Previews are
     * fetched one at a time so they fill in sequentially and go easy on the
     * server rather than bursting every request at once.
     */
    Q_INVOKABLE void requestPreview(const QString &name);

    /*!
     * \brief The /desktop/asteroid/watchface value for an installed face,
     * so QML can activate a community face on tap.
     */
    Q_INVOKABLE QString watchfaceUrl(const QString &name) const;

    /*!
     * \brief Whether a face declares a settingsPage, from a cached scan of its
     * QML source. The selector needs this for the settings affordances without
     * instantiating the face: the live tile render is only a fallback for
     * faces lacking a preview image, so an instantiated item is usually not
     * available to ask.
     */
    Q_INVOKABLE bool faceHasSettings(const QString &name) const;

    /*!
     * \brief Install a community watchface: its QML, image assets and fonts.
     * Updates the row's Downloading/Progress/Installed roles as it runs and
     * activates the face on success.
     */
    Q_INVOKABLE void install(const QString &name);

    /*!
     * \brief Remove a community watchface and all of its user-folder assets.
     * Activation passes to the nearest face still installed.
     */
    Q_INVOKABLE void remove(const QString &name);

signals:
    void activeWatchfaceChanged();
    void onlineChanged();
    void loadingChanged();
    void hasCatalogChanged();
    void browseActiveChanged();
    void previewSizeChanged();

    //! Emitted after a successful install so QML can point the active
    //! watchface key at the new face. \a value is the full file:// URL.
    void activated(const QString &value);

    //! Emitted when an install fails, for a transient UI cue.
    void installFailed(const QString &name);

    //! Emitted once, only on a fresh install and only when the watchface shipped
    //! its own wallpaper, so QML can set it as the background and a peek shows the
    //! face on its designed wallpaper. Never emitted on re-activation, so the
    //! user's later wallpaper choice is respected. \a url is the file:// path in
    //! the user wallpaper folder.
    void wallpaperForced(const QString &url);

private:
    struct Entry {
        QString name;
        bool    installed  = false;
        bool    downloading = false;
        qreal   progress   = 0.0;
        bool    failed     = false;
        bool    stock      = false; //!< shipped in the system dir, not the community catalog
        QString missingModule;      //!< non-empty = an imported module is not installed here; face is unavailable
        bool    moduleChecked = false; //!< imports probed once; missingModule is authoritative
    };

    // Rows from a catalog name list plus what is on disk.
    void        rebuildFrom(const QStringList &names);
    int         indexOfName(const QString &name) const;
    //! Nearest still-installed row to \a row, preferring the one above.
    int         nearestInstalled(int row) const;
    void        updateEntry(int row, const QList<int> &roles);
    bool        isInstalledOnDisk(const QString &name) const;
    // Top-level *.qml in the user watchface folder = installed user faces. A
    // face's variant components live in a <name>/ subfolder and are not listed,
    // so a bare .qml dropped in by any means (store, script, manual copy) shows.
    QStringList installedWatchfaceNames() const;
    // Re-list from the last catalog plus the current on-disk faces. Bound to the
    // folder watcher so a face added or removed on disk appears or leaves live.
    void        rebuildFromCatalogAndDisk();

    // The user wallpaper folder (file:// URL), where install() delivers a
    // face's bundled wallpaper.
    QString userWallpaperPath() const;

    // Activation URL for the /desktop/asteroid/watchface key.
    QString activationValue(const QString &name) const;

    // What an install means for a row, for activation and for the import gate.
    void onInstallProgress(const QString &name, qreal fraction);
    void onInstallFinished(const QString &name, bool success, const QString &wallpaper);


    QList<Entry>           m_entries;
    QString                m_activeWatchface;
    bool                   m_browseActive = false;
    QNetworkAccessManager *m_nam;
    WatchfaceCatalog      *m_catalog = nullptr;
    WatchfaceInstaller    *m_installer = nullptr;
    WatchfacePreviews     *m_previews = nullptr;
    WatchfaceQmlProbe      m_probe;
    QFileSystemWatcher    *m_dirWatcher = nullptr;
    QFileSystemWatcher    *m_previewWatcher = nullptr;
    QTimer                *m_dirDebounce = nullptr;
    QTimer                *m_previewDebounce = nullptr;
    QSet<QString>          m_pendingDiskSet;
};

#endif // WATCHFACESTOREMODEL_H
