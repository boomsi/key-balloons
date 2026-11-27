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
  set_source_files_properties(assets/KeyBalloons.icns PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
  target_sources(key_balloons PRIVATE assets/KeyBalloons.icns)
  target_link_libraries(key_balloons PRIVATE
    "${APPKIT_FRAMEWORK}" "${APPLICATION_SERVICES_FRAMEWORK}" "${CARBON_FRAMEWORK}")
  set_target_properties(key_balloons PROPERTIES
    MACOSX_BUNDLE_BUNDLE_NAME "Key Balloons"
    MACOSX_BUNDLE_GUI_IDENTIFIER "io.github.boomsi.keyballoons"
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/src/macos/Info.plist.in"
    MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}")
elseif(WIN32)
  enable_language(RC)
  target_sources(key_balloons PRIVATE src/windows/keyboard_monitor.cpp assets/KeyBalloons.rc)
  target_include_directories(key_balloons PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/assets")
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

install(TARGETS key_balloons
  BUNDLE DESTINATION .
  RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")

set(deploy_options NO_TRANSLATIONS)
if(APPLE)
  list(APPEND deploy_options DEPLOY_TOOL_OPTIONS "-codesign=-")
elseif(WIN32 AND MSVC)
  # Install the Visual C++ runtime DLLs next to the executable for app-local use.
  set(CMAKE_INSTALL_SYSTEM_RUNTIME_DESTINATION "${CMAKE_INSTALL_BINDIR}")
  include(InstallRequiredSystemLibraries)
  list(APPEND deploy_options NO_COMPILER_RUNTIME)
endif()
qt_generate_deploy_qml_app_script(
  TARGET key_balloons
  OUTPUT_SCRIPT deploy_script
  ${deploy_options})
install(SCRIPT "${deploy_script}")

set(CPACK_PACKAGE_NAME "KeyBalloons")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "Key Balloons")
if(APPLE)
  set(CPACK_GENERATOR DragNDrop)
  set(CPACK_DMG_VOLUME_NAME "Key Balloons")
  set(CPACK_PACKAGE_FILE_NAME "KeyBalloons-${PROJECT_VERSION}-macOS")
elseif(WIN32)
  set(CPACK_GENERATOR NSIS)
  set(CPACK_NSIS_DISPLAY_NAME "Key Balloons")
  set(CPACK_NSIS_MUI_ICON "${CMAKE_CURRENT_SOURCE_DIR}/assets/KeyBalloons.ico")
  set(CPACK_NSIS_MUI_UNIICON "${CPACK_NSIS_MUI_ICON}")
  set(CPACK_NSIS_EXECUTABLES_DIRECTORY "${CMAKE_INSTALL_BINDIR}")
  set(CPACK_PACKAGE_EXECUTABLES "KeyBalloons" "Key Balloons")
  set(CPACK_PACKAGE_FILE_NAME "KeyBalloons-${PROJECT_VERSION}-Windows-x64")
endif()
include(CPack)

include(CTest)
if(BUILD_TESTING)
  find_package(Qt6 6.10 REQUIRED COMPONENTS QuickTest)
  qt_add_executable(key_balloons_tests tests/quick_test.cpp)
  target_link_libraries(key_balloons_tests PRIVATE Qt6::QuickTest Qt6::Quick)
  add_test(NAME key_balloons_qml COMMAND key_balloons_tests
    -platform offscreen -input "${CMAKE_CURRENT_SOURCE_DIR}/tests/tst_balloons.qml")
  set_tests_properties(key_balloons_qml PROPERTIES ENVIRONMENT "QT_QUICK_BACKEND=software")
endif()
