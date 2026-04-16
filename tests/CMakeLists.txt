cmake_minimum_required(VERSION 3.10.0)

# Can be built standalone:  cd tests && mkdir build && cd build && cmake .. && make && ctest -V
# Or as part of asteroid-settings:  cmake .. -DBUILD_TESTS=ON
if(NOT CMAKE_PROJECT_NAME OR CMAKE_PROJECT_NAME STREQUAL "asteroid-settings-tests")
    project(asteroid-settings-tests)
    set(STANDALONE_TEST TRUE)
endif()

find_package(Qt5 COMPONENTS Test Qml Quick Gui REQUIRED)
set(CMAKE_AUTOMOC ON)

# When built standalone, CMAKE_SOURCE_DIR points at tests/ itself,
# so QML_SOURCE_DIR must go one level up.
if(STANDALONE_TEST)
    set(SETTINGS_SOURCE_DIR "${CMAKE_SOURCE_DIR}/..")
else()
    set(SETTINGS_SOURCE_DIR "${CMAKE_SOURCE_DIR}")
endif()

# Paths for test discovery of QML files and mock modules
add_definitions(-DQML_SOURCE_DIR="${SETTINGS_SOURCE_DIR}/src/qml")
add_definitions(-DMOCK_QML_DIR="${CMAKE_CURRENT_SOURCE_DIR}/mock-qml")

# QML validation test — catches white-screen regressions
add_executable(tst_qmlvalidation tst_qmlvalidation.cpp)
target_link_libraries(tst_qmlvalidation
    Qt5::Test
    Qt5::Qml
    Qt5::Quick
    Qt5::Gui
)

if(STANDALONE_TEST)
    enable_testing()
endif()

add_test(NAME tst_qmlvalidation COMMAND tst_qmlvalidation)

# Run headless — no display needed for load-time validation
set_tests_properties(tst_qmlvalidation PROPERTIES
    ENVIRONMENT "QT_QPA_PLATFORM=offscreen"
)
