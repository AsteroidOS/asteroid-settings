/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef WATCHFACEPREVIEWS_H
#define WATCHFACEPREVIEWS_H

#include <QHash>
#include <QObject>
#include <QString>
#include <QStringList>

class QNetworkAccessManager;

/*!
 * \brief Finds the image a watchface tile should show, and fetches it if absent.
 *
 * Resolution walks a fixed order of sources, from the one that best matches
 * this device to the most generic; see previewPathFor(). Results are memoized
 * including misses, because a tile asks once per row and again on every
 * refresh.
 *
 * A face with no preview anywhere can have one downloaded from the repo, one
 * at a time. Owns no list state: it reports a finished download by name and
 * the model decides which row that is.
 */
class WatchfacePreviews : public QObject
{
    Q_OBJECT

public:
    explicit WatchfacePreviews(QNetworkAccessManager *nam, QObject *parent = nullptr);

    /*!
     * The pixel size tiles are drawn at. Preview folders are named by pixel
     * size and the sizes present are whatever the launcher grabbed plus
     * whatever a face shipped, so resolution picks the nearest folder rather
     * than the first. Supplied by the caller because it comes from Dims, which
     * lives in QML.
     */
    void setPreviewSize(int px);
    int previewSize() const;

    /*!
     * The preview file for \a name, or an empty string when the face has none.
     *
     * In order: the transparent preview the launcher grabbed for this device,
     * the transparent master the face ships, the stock master, the older
     * per-size stock PNG set, then a downloaded gallery thumbnail.
     */
    QString pathFor(const QString &name) const;

    //! Where a downloaded gallery thumbnail for \a name is cached.
    QString galleryCachePathFor(const QString &name) const;

    //! Queues a download for \a name when nothing resolves for it yet.
    void request(const QString &name);

    //! Drops the memoized resolution for \a name, or for every name.
    void forget(const QString &name);
    void forgetAll();

Q_SIGNALS:
    //! A download landed and \a name now resolves to a file it did not before.
    void previewReady(const QString &name);

private:
    void startNext();

    QNetworkAccessManager *m_nam = nullptr;
    int m_previewSize = 0;
    bool m_busy = false;
    QStringList m_queue;
    mutable QHash<QString, QString> m_paths;
};

#endif // WATCHFACEPREVIEWS_H
