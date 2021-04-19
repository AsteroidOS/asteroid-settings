TARGET = asteroid-settings
CONFIG += asteroidapp link_pkgconfig
PKGCONFIG += dbus-1 dbus-glib-1 asteroidapp
QT += dbus multimedia qml quick

system(qdbusxml2cpp -p mceiface.h:mceiface.cpp mce.xml)

SOURCES +=     main.cpp volumecontrol.cpp mceiface.cpp tilttowake.cpp taptowake.cpp
HEADERS +=     volumecontrol.h tilttowake.h taptowake.h mceiface.h
RESOURCES +=   resources.qrc
OTHER_FILES += main.qml \
               ListItem.qml \
               LanguagePage.qml \
               TimePage.qml \
               DatePage.qml \
               BluetoothPage.qml \
               DisplayPage.qml \
               SoundPage.qml \
               UnitsPage.qml \
               USBPage.qml \
               WatchfacePage.qml \
               PoweroffPage.qml \
               RebootPage.qml \
               RestartPage.qml \
               AboutPage.qml

lupdate_only{ SOURCES += i18n/asteroid-settings.desktop.h }
TRANSLATIONS = $$files(i18n/$$TARGET.*.ts)

target.path = /usr/bin/
INSTALLS += target
