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

#ifndef WATCHFACEHELPER_H
#define WATCHFACEHELPER_H

#include <QNetworkAccessManager>
#include <QObject>
#include <QQmlEngine>
#include <QString>

class WatchfaceHelper : public QObject
{
    Q_OBJECT
    
public:
    explicit WatchfaceHelper(QObject *parent = nullptr);
    static WatchfaceHelper *instance();
    static QObject *qmlInstance(QQmlEngine *engine, QJSEngine *scriptEngine);
    
    /*!
     * \brief Download a remote URL and write to destPath.
     * destPath must be within an allowed user-writable path — blocked otherwise.
     */
    Q_INVOKABLE void    downloadFile(const QString &url, const QString &destPath);
    
    /*!
     * \brief Remove all user-folder files belonging to a community watchface.
     */
    Q_INVOKABLE bool    removeWatchface(const QString &name);
    
    /*!
     * \brief Create a directory path recursively (mkdir -p equivalent).
     */
    Q_INVOKABLE bool    mkpath(const QString &dirPath);
    
    /*!
     * \brief Rebuild the fontconfig user cache after font install.
     */
    Q_INVOKABLE void    restartSession();
    
    /*!
     * \brief Base path for cached watchface store thumbnails.
     * Returns QStandardPaths::CacheLocation + "/watchface-store/"
     */
    Q_INVOKABLE QString cachePath() const;
    
    /*!
     * \brief User-writable watchface QML directory.
     * Returns ~/.local/share/asteroid-launcher/watchfaces/
     */
    Q_INVOKABLE QString userWatchfacePath() const;
    
    /*!
     * \brief User-writable asteroid-launcher data root as file:// URL.
     * Returns file://~/.local/share/asteroid-launcher/
     */
    Q_INVOKABLE QString userAssetPath() const;
    
    /*!
     * \brief User-writable fonts directory.
     * Returns ~/.fonts/
     */
    Q_INVOKABLE QString userFontsPath() const;
    
    /*!
     * \brief Read a file from the cache location and return its contents.
     * Only files within cachePath() are readable — all other paths are blocked.
     */
    Q_INVOKABLE QString readFile(const QString &path) const;
    
    /*!
     * \brief Write content to a file at destPath.
     * destPath must be within an allowed user-writable path — blocked otherwise.
     */
    Q_INVOKABLE bool    writeFile(const QString &path, const QString &content);
    
signals:
    /*!
     * \brief Emitted when a removeWatchface() call succeeds in deleting the QML.
     */
    void watchfaceRemoved(const QString &name);

    /*!
     * \brief Emitted when a downloadFile() call completes.
     * \param destPath the destination path originally requested
     * \param success  true if the file was written successfully
     */
    void downloadComplete(const QString &destPath, bool success);
    
    /*!
     * \brief Emitted periodically during a download for progress tracking.
     */
    void downloadProgress(const QString &destPath, qint64 received, qint64 total);
    
private:
    bool    isPathAllowed(const QString &path) const;
    QString userDataPath() const;
    
    QNetworkAccessManager *m_nam;
    static WatchfaceHelper *s_instance;
};

#endif // WATCHFACEHELPER_H
