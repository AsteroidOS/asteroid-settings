cmake_minimum_required(VERSION 3.10.0)

project(asteroid-settings
	VERSION 0.0.1
	DESCRIPTION "Default settings app for AsteroidOS")

find_package(ECM REQUIRED NO_MODULE)
find_package(AsteroidApp REQUIRED)

set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ASTEROID_MODULE_PATH} ${CMAKE_SOURCE_DIR}/cmake)

include(FindPkgConfig)
include(FeatureSummary)
include(GNUInstallDirs)
include(ECMFindQmlModule)
include(AsteroidCMakeSettings)
include(AsteroidTranslations)

find_package(Qt5 COMPONENTS Core Qml Quick DBus Multimedia REQUIRED)
find_package(DBus1 REQUIRED)
find_package(Mce REQUIRED)

find_package(PkgConfig)
pkg_check_modules(DBUSGLIB dbus-glib-1 IMPORTED_TARGET REQUIRED)
set_property(GLOBAL APPEND PROPERTY _CMAKE_dbus-glib-1_TYPE REQUIRED)

if(DBUSGLIB_FOUND)
	set_property(GLOBAL APPEND PROPERTY PACKAGES_FOUND dbus-glib-1)
else()
	set_property(GLOBAL APPEND PROPERTY PACKAGES_NOT_FOUND dbus-glib-1)
endif()

ecm_find_qmlmodule(Nemo.DBus 2.0)
ecm_find_qmlmodule(Nemo.Configuration 1.0)
ecm_find_qmlmodule(Qt.labs.folderlistmodel 2.1)
ecm_find_qmlmodule(org.nemomobile.systemsettings 1.0)

add_subdirectory(src)

build_translations(i18n)
generate_desktop(${CMAKE_SOURCE_DIR} asteroid-settings)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
