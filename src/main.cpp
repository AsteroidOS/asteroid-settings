/*
 * Copyright (C) 2017 - Florent Revest <revestflo@gmail.com>
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

#include <QGuiApplication>
#include <QQuickView>
#include <QScreen>
#include <QtQml>
#include <sys/utsname.h>

#include <asteroidapp.h>

#include "volumecontrol.h"
#include "tilttowake.h"
#include "taptowake.h"

int main(int argc, char *argv[])
{
    utsname buf;
    uname(&buf);
    QScopedPointer<QGuiApplication> app(AsteroidApp::application(argc, argv));
    QScopedPointer<QQuickView> view(AsteroidApp::createView());
    qmlRegisterType<VolumeControl>("org.asteroid.settings", 1, 0, "VolumeControl");
    qmlRegisterType<TiltToWake>("org.asteroid.settings", 1, 0, "TiltToWake");
    qmlRegisterType<TapToWake>("org.asteroid.settings", 1, 0, "TapToWake");
    view->setSource(QUrl("qrc:/qml/main.qml"));
    view->rootContext()->setContextProperty("qtVersion", QString(qVersion()));
    view->rootContext()->setContextProperty("kernelVersion", QString(buf.release));
    view->resize(app->primaryScreen()->size());
    view->show();
    return app->exec();
}
