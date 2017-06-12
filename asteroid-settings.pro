TARGET = asteroid-settings
CONFIG += asteroidapp

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
              AboutPage.qml \
              i18n/$$TARGET.desktop.h
}
TRANSLATIONS = $$files(i18n/$$TARGET.*.ts)
