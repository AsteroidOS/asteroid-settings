TEMPLATE = app
QT += qml quick
CONFIG += link_pkgconfig
PKGCONFIG += qdeclarative5-boostable

SOURCES +=     main.cpp
RESOURCES +=   resources.qrc
OTHER_FILES += main.qml \
               ListItem.qml \
               LanguagePage.qml \
               TimePage.qml \
               DatePage.qml \
               BluetoothPage.qml \
               BrightnessPage.qml \
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
              USBPage.qml \
              WatchfacePage.qml \
              PoweroffPage.qml \
              RebootPage.qml \
              RestartPage.qml \
              AboutPage.qml
}

TARGET = asteroid-settings
target.path = /usr/bin/

desktop.path = /usr/share/applications
desktop.files = asteroid-settings.desktop

INSTALLS += target desktop
