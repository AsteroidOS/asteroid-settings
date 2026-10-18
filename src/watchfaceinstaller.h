/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef WATCHFACEINSTALLER_H
#define WATCHFACEINSTALLER_H

#include <QHash>
#include <QObject>
#include <QString>
#include <QStringList>

class QNetworkAccessManager;

/*!
 * \brief Downloads a watchface's files into the user folder as one transaction.
 *
 * A face is its QML plus optional assets: sibling scripts, images, a bundled
 * wallpaper and fonts. Every file is read from the cached repository tree and
 * pulled from raw, so an install makes no rate-limited API call. Only the QML
 * is essential; a missing asset does not fail the install.
 *
 * Files are written atomically, so no observer — the launcher's folder
 * watchers, its font registration, the store's own disk enumeration — can see
 * a half-written face.
 *
 * Reports progress and completion by name. What that means for a list row, for
 * activation or for the import gate is the caller's business.
 */
class WatchfaceInstaller : public QObject
{
    Q_OBJECT

public:
    explicit WatchfaceInstaller(QNetworkAccessManager *nam, QObject *parent = nullptr);
    ~WatchfaceInstaller() override;

    //! Whether \a name has a transaction in flight.
    bool isInstalling(const QString &name) const;

    //! Whether any transaction is in flight.
    bool busy() const;

    /*!
     * Starts installing \a name, enumerating its files from \a tree.
     * \a wallpaperDestBase is the file:// folder a bundled wallpaper lands in,
     * reported back through finished() so the caller can apply it once.
     * Does nothing when \a name is already installing.
     */
    void start(const QString &name, const QStringList &tree, const QString &wallpaperDestBase);

Q_SIGNALS:
    //! \a fraction of this face's files are written, 0.0..1.0.
    void progress(const QString &name, qreal fraction);

    /*!
     * The transaction ended. \a success is false when the essential QML failed.
     * \a wallpaper is the bundled wallpaper's destination URL, empty when the
     * face ships none.
     */
    void finished(const QString &name, bool success, const QString &wallpaper);

private:
    struct Transaction;

    void queueFile(Transaction *tx, const QString &url, const QString &dest, bool isQml);
    void queueTreeDir(Transaction *tx, const QStringList &tree, const QString &repoDir,
                      const QString &destPrefix, const QString &skip = QString());
    void maybeFinish(Transaction *tx);

    QNetworkAccessManager *m_nam = nullptr;
    QHash<QString, Transaction *> m_transactions;
};

#endif // WATCHFACEINSTALLER_H
