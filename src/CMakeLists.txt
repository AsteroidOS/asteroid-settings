# Generate DBus interfaces
qt_add_dbus_interfaces(
	dbus_srcs
	${CMAKE_CURRENT_SOURCE_DIR}/mce.xml
)

qt_add_dbus_interfaces(
	dbus_srcs
	${CMAKE_CURRENT_SOURCE_DIR}/VolumeControl2.xml
)

set(
	SRC
	main.cpp
	sysinfo.cpp
	taptowake.cpp
	tilttowake.cpp
	volumecontrol.cpp
	${dbus_srcs}
)
set(
	HEADERS
	sysinfo.h
	taptowake.h
	tilttowake.h
	volumecontrol.h
)

add_library(asteroid-settings ${SRC} ${HEADERS})
asteroid_app_qml_module(asteroid-settings
	qml/main.qml
	qml/LanguagePage.qml
	qml/TimePage.qml
	qml/DatePage.qml
	qml/TimezonePage.qml
	qml/BluetoothPage.qml
	qml/DisplayPage.qml
	qml/SoundPage.qml
	qml/NightstandPage.qml
	qml/NightstandWatchfacePage.qml
	qml/UnitsPage.qml
	qml/QuickPanelPage.qml
	qml/WallpaperPage.qml
	qml/WatchfacePage.qml
	qml/WatchfaceSelector.qml
	qml/LauncherPage.qml
	qml/USBPage.qml
	qml/PowerPage.qml
	qml/AboutPage.qml
)
message(${CMAKE_CURRENT_BINARY_DIR})
target_include_directories(
	asteroid-settings
	PRIVATE
	${GENERATED_DBUS_HEADERS_DIR}
)
set_target_properties(asteroid-settings PROPERTIES PREFIX "")

target_link_libraries(
	asteroid-settings
	PRIVATE
		Qt::Qml
		Qt::Quick
		Qt::DBus
		Qt::Multimedia
		Asteroid::AsteroidApp6
)

install(
	TARGETS asteroid-settings
	DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
