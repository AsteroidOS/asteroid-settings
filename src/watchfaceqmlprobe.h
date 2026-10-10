/*
 * SPDX-FileCopyrightText: 2026 Timo Könnecke <github.com/moWerk>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef WATCHFACEQMLPROBE_H
#define WATCHFACEQMLPROBE_H

#include <QHash>
#include <QString>

class QQmlEngine;

/*!
 * \brief Answers what a watchface needs and what it offers, by reading its QML.
 *
 * Two questions the store asks about a face before showing it: are the modules
 * it imports present on this device, and does it declare a settings page. Both
 * are answered by inspecting the face's source, and both are cached because
 * they are asked once per list row and again on every refresh.
 *
 * Holds no store state and does no networking. Given a face name it reads from
 * disk; given a module URI it asks a QML engine.
 */
class WatchfaceQmlProbe
{
public:
    /*!
     * The engine used to resolve module imports. As a singleton the store is
     * not attached to an engine the way a QML-declared object is, so the
     * caller hands one in.
     */
    void setQmlEngine(QQmlEngine *engine);

    /*!
     * Adopts \a fallback when no engine has been set yet. The store is
     * constructed before an engine exists, so callers that probe from a const
     * path use this to supply one late rather than fail open forever.
     */
    void ensureEngine(QQmlEngine *fallback) const;

    //! Whether \a uri resolves on this device's QML import path.
    bool moduleAvailable(const QString &uri) const;

    /*!
     * The first module \a qmlPath imports that is missing here, or an empty
     * string when every import resolves.
     */
    QString firstUnmetImport(const QString &qmlPath) const;

    //! Whether the face \a name declares a settingsPage property.
    bool hasSettings(const QString &name) const;

    //! Drops the cached answers for \a name, which its .qml changing invalidates.
    void forget(const QString &name);

private:
    mutable QQmlEngine *m_engine = nullptr;
    mutable QHash<QString, bool> m_moduleAvail;
    mutable QHash<QString, bool> m_hasSettings;
};

#endif // WATCHFACEQMLPROBE_H
