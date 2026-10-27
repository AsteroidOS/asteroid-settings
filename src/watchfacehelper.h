/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef WATCHFACEHELPER_H
#define WATCHFACEHELPER_H

#include <QObject>
#include <QString>

/*!
 * \brief Filesystem side of the watchface store: canonical paths and the
 * destructive operations.
 *
 * The store model owns all networking and the model rows; this helper owns
 * where things live on disk (user watchface, asset, font and cache folders)
 * and the two operations that reach outside the model: removing an installed
 * face's files and restarting the launcher session.
 *
 * Accessed only through instance(); the constructor is private, has no side
 * effects, and the instance is created on first use, so merely opening a
 * settings page costs nothing here.
 */
class WatchfaceHelper : public QObject
{
    Q_OBJECT

    //! The user asset root as a file:// URL. Exposed because pages that only
    //! need a path (WallpaperPage listing user wallpapers) should not have to
    //! construct the store model to get one.
    Q_PROPERTY(QString userAssetPath READ userAssetPath CONSTANT)

public:
    static WatchfaceHelper *instance();

    //! Root of the user's launcher data (…/asteroid-launcher/), trailing slash.
    QString userDataPath() const;

    //! The user watchface folder (userDataPath() + watchfaces/).
    QString userWatchfacePath() const;

    //! userDataPath() as a file:// URL, for QML consumers.
    QString userAssetPath() const;

    //! The user font folder the store installs bundled fonts into. This is the
    //! legacy ~/.fonts location on purpose: it is what the shipped fontconfig
    //! scans and what the launcher's runtime font registration watches on this
    //! platform. Moving to the XDG font dir is a coordinated follow-up across
    //! launcher and settings.
    QString userFontsPath() const;

    //! The store's cache folder (catalog, repo tree, gallery thumbnails).
    QString cachePath() const;

    /*!
     * \brief Remove an installed face's files: its QML, its variant subfolder,
     * its launcher-grabbed previews and its image assets.
     *
     * Bundled fonts are deliberately retained — they may be shared between
     * faces and cost nothing to re-download — as is a bundled wallpaper the
     * user may still have selected. \a name must be a bare face name; anything
     * containing path separators or glob characters is refused.
     */
    void removeWatchface(const QString &name);


private:
    explicit WatchfaceHelper(QObject *parent = nullptr);
    Q_DISABLE_COPY(WatchfaceHelper)
};

#endif // WATCHFACEHELPER_H
