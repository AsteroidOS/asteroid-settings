cmake_minimum_required(VERSION 3.10.0)

project(asteroid-settings
	VERSION 1.0.0
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
find_package(Mce REQUIRED)

ecm_find_qmlmodule(Nemo.DBus 2.0)
ecm_find_qmlmodule(Nemo.Configuration 1.0)
ecm_find_qmlmodule(Qt.labs.folderlistmodel 2.1)
ecm_find_qmlmodule(org.nemomobile.systemsettings 1.0)

add_subdirectory(src)

build_translations(i18n)
generate_desktop(${CMAKE_SOURCE_DIR} asteroid-settings)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)

set(CPACK_GENERATOR "DEB")
string(TOLOWER "${CMAKE_PROJECT_NAME}" lcproject_name)
set(CPACK_DEBIAN_FILE_NAME "${lcproject_name}-${CMAKE_PROJECT_VERSION}.ipk")
set(CPACK_STRIP_FILES TRUE)
set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE armv7vehf-neon)
if (NOT CPACK_PACKAGE_CONTACT) 
    set(CPACK_PACKAGE_CONTACT bogus@example.org)
    message(WARNING "No package contact specified: using ${CPACK_PACKAGE_CONTACT}")
endif()
include(CPack)
