TARGET = asteroid-settings
CONFIG += asteroidapp
PKGCONFIG += dbus-1 dbus-glib-1
QT += dbus multimedia

SOURCES +=     main.cpp volumecontrol.cpp
HEADERS +=     volumecontrol.h
RESOURCES +=   resources.qrc
OTHER_FILES += main.qml \
               ListItem.qml \
               LanguagePage.qml \
               TimePage.qml \
               DatePage.qml \
               BluetoothPage.qml \
               BrightnessPage.qml \
               SoundPage.qml \
               USBPage.qml \
               WatchfacePage.qml \
               PoweroffPage.qml \
               RebootPage.qml \
               RestartPage.qml \
               AboutPage.qml

lupdate_only{
    SOURCES = main.qml \
              ListItem.qml \
              LanguagePage.qml \
              TimePage.qml \
              DatePage.qml \
              BluetoothPage.qml \
              BrightnessPage.qml \
              SoundPage.qml \
              USBPage.qml \
              WatchfacePage.qml \
              PoweroffPage.qml \
              RebootPage.qml \
              RestartPage.qml \
              AboutPage.qml \
              i18n/$$TARGET.desktop.h
}
TRANSLATIONS = $$files(i18n/$$TARGET.*.ts)
