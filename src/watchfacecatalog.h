/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef WATCHFACECATALOG_H
#define WATCHFACECATALOG_H

#include <QObject>
#include <QString>
#include <QStringList>

class QNetworkAccessManager;

/*!
 * \brief What the watchface repository offers, fetched and cached.
 *
 * Two listings, both conditional on an ETag so a revalidation that changes
 * nothing costs one 304: the catalog of face directories, and one recursive
 * tree of every file in the repo. The tree exists so an install can enumerate
 * a face's files locally; the contents API allows 60 calls an hour per IP and
 * per-directory calls would exhaust that after a couple of installs.
 *
 * Knows nothing about rows, installs or previews. It reports that the name
 * list changed and the caller decides what that means for its model.
 */
class WatchfaceCatalog : public QObject
{
    Q_OBJECT

public:
    explicit WatchfaceCatalog(QNetworkAccessManager *nam, QObject *parent = nullptr);

    //! False when the repository is unreachable.
    bool online() const;

    //! True while the catalog is being fetched.
    bool loading() const;

    //! True once a catalog has been cached, which lets the caller label the
    //! store action "update" rather than "get more".
    bool hasCatalog() const;

    //! Face names from the catalog, empty until loadCached() or a fetch.
    QStringList names() const;

    //! Every file path in the repo, from the cached tree.
    QStringList treePaths() const;

    //! Repository directories that are not watchfaces.
    static bool isSkippedDir(const QString &name);

    //! HEADs a stable raw file. Cheaper than the API and not rate limited.
    void probeOnline();

    //! Parses the cached catalog so rows appear without waiting on the network.
    void loadCached();

    //! Revalidates the catalog and the tree.
    void fetch();

Q_SIGNALS:
    void onlineChanged();
    void loadingChanged();
    void hasCatalogChanged();

    //! names() changed, so anything derived from it needs rebuilding.
    void namesChanged();

private:
    void fetchCatalog();
    void fetchTree();
    void setOnline(bool v);
    void setLoading(bool v);

    QString catalogCachePath() const;
    QString treeCachePath() const;
    QByteArray readCachedEtag() const;
    QByteArray readTreeEtag() const;
    void writeCatalogCache(const QByteArray &body, const QByteArray &etag);
    void writeTreeCache(const QStringList &paths, const QByteArray &etag);
    QStringList parseCatalog(const QByteArray &body) const;
    QStringList parseTree(const QByteArray &body) const;

    QNetworkAccessManager *m_nam = nullptr;
    bool m_online = false;
    bool m_loading = false;
    QStringList m_names;
};

#endif // WATCHFACECATALOG_H
