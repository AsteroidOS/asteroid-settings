/*
 * Copyright (C) 2016 - Sylvia van Os <iamsylvie@openmailbox.org>
 * Copyright (C) 2015 - Florent Revest <revestflo@gmail.com>
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

#include <QQuickView>
#include <QTranslator>
#include <QGuiApplication>
#include <MDeclarativeCache>

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(MDeclarativeCache::qApplication(argc, argv));

    QTranslator translator;
    translator.load(QLocale(), "asteroid-settings", ".", "/usr/share/translations", ".qm");
    app->installTranslator(&translator);

    QScopedPointer<QQuickView> view(MDeclarativeCache::qQuickView());
    view->setSource(QUrl("qrc:/main.qml"));
    view->setTitle("Settings");
    view->showFullScreen();
    return app->exec();
}
