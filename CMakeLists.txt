cmake_minimum_required(VERSION 3.21)
project(KeyBalloons VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Qt6 6.10 REQUIRED COMPONENTS Quick Widgets)
qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(key_balloons WIN32 MACOSX_BUNDLE
  src/main.cpp
  src/keyboard_monitor.h
  src/tray_controls.cpp
  src/tray_controls.h)
target_link_libraries(key_balloons PRIVATE Qt6::Quick Qt6::Widgets)
set_target_properties(key_balloons PROPERTIES OUTPUT_NAME KeyBalloons)

if(APPLE)
  enable_language(OBJCXX)
  find_library(APPKIT_FRAMEWORK AppKit REQUIRED)
  find_library(APPLICATION_SERVICES_FRAMEWORK ApplicationServices REQUIRED)
  find_library(CARBON_FRAMEWORK Carbon REQUIRED)
  target_sources(key_balloons PRIVATE src/macos/keyboard_monitor.cpp src/macos/overlay.mm)
  target_link_libraries(key_balloons PRIVATE
    "${APPKIT_FRAMEWORK}" "${APPLICATION_SERVICES_FRAMEWORK}" "${CARBON_FRAMEWORK}")
  set_target_properties(key_balloons PROPERTIES
    MACOSX_BUNDLE_BUNDLE_NAME "Key Balloons"
    MACOSX_BUNDLE_GUI_IDENTIFIER "io.github.boomsi.keyballoons"
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/src/macos/Info.plist.in"
    MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}")
elseif(WIN32)
  target_sources(key_balloons PRIVATE src/windows/keyboard_monitor.cpp)
  target_link_libraries(key_balloons PRIVATE user32)
  if(MSVC)
    target_compile_options(key_balloons PRIVATE /utf-8)
  endif()
else()
  message(FATAL_ERROR "Key Balloons supports macOS and Windows.")
endif()

set(qml_sources qml/Main.qml qml/BalloonField.qml qml/GlassBox.qml qml/KeyBalloon.qml)
foreach(source IN LISTS qml_sources)
  get_filename_component(file_name "${source}" NAME)
  set_source_files_properties("${source}" PROPERTIES QT_RESOURCE_ALIAS "${file_name}")
endforeach()
qt_add_qml_module(key_balloons URI KeyBalloons QML_FILES ${qml_sources})

include(CTest)
if(BUILD_TESTING)
  find_package(Qt6 6.10 REQUIRED COMPONENTS QuickTest)
  qt_add_executable(key_balloons_tests tests/quick_test.cpp)
  target_link_libraries(key_balloons_tests PRIVATE Qt6::QuickTest Qt6::Quick)
  add_test(NAME key_balloons_qml COMMAND key_balloons_tests
    -platform offscreen -input "${CMAKE_CURRENT_SOURCE_DIR}/tests/tst_balloons.qml")
  set_tests_properties(key_balloons_qml PROPERTIES ENVIRONMENT "QT_QUICK_BACKEND=software")
endif()
