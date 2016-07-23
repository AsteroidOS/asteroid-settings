TEMPLATE = app
QT += widgets qml quick bluetooth
CONFIG += link_pkgconfig
PKGCONFIG += qdeclarative5-boostable

SOURCES +=     main.cpp
RESOURCES +=   resources.qrc
OTHER_FILES += main.qml \
               GridItem.qml \
               LanguagePage.qml \
               TimePage.qml \
               DatePage.qml \
               BluetoothPage.qml \
               BrightnessPage.qml \
               USBPage.qml \
               WatchfacePage.qml \
               PoweroffPage.qml \
               RestartPage.qml \
               AboutPage.qml

lupdate_only{
    SOURCES = main.qml \
              GridItem.qml \
              LanguagePage.qml \
              TimePage.qml \
              DatePage.qml \
              BluetoothPage.qml \
              BrightnessPage.qml \
              USBPage.qml \
              WatchfacePage.qml \
              PoweroffPage.qml \
              RestartPage.qml \
              AboutPage.qml
}

TRANSLATIONS = asteroid-settings.nl_NL.ts

TARGET = asteroid-settings
target.path = /usr/bin/

desktop.path = /usr/share/applications
desktop.files = asteroid-settings.desktop

INSTALLS += target desktop
