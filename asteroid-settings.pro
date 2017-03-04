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
              AboutPage.qml \
              i18n/asteroid-settings.desktop.h
}

# Needed for lupdate
TRANSLATIONS = i18n/asteroid-settings.ca.ts \
               i18n/asteroid-settings.ckb.ts \
               i18n/asteroid-settings.cs.ts \
               i18n/asteroid-settings.de.ts \
               i18n/asteroid-settings.el.ts \
               i18n/asteroid-settings.es.ts \
               i18n/asteroid-settings.fa.ts \
               i18n/asteroid-settings.fr.ts \
               i18n/asteroid-settings.hu.ts \
               i18n/asteroid-settings.it.ts \
               i18n/asteroid-settings.kab.ts \
               i18n/asteroid-settings.ko.ts \
               i18n/asteroid-settings.nl.ts \
               i18n/asteroid-settings.pl.ts \
               i18n/asteroid-settings.pt_BR.ts \
               i18n/asteroid-settings.ru.ts \
               i18n/asteroid-settings.sk.ts \
               i18n/asteroid-settings.sv.ts \
               i18n/asteroid-settings.ta.ts \
               i18n/asteroid-settings.tr.ts \
               i18n/asteroid-settings.uk.ts \
               i18n/asteroid-settings.zh_Hans.ts

TARGET = asteroid-settings
target.path = /usr/bin/

desktop.commands = bash $$PWD/i18n/generate-desktop.sh $$PWD asteroid-settings.desktop
desktop.path = /usr/share/applications
desktop.files = $$OUT_PWD/asteroid-settings.desktop

INSTALLS += target desktop
