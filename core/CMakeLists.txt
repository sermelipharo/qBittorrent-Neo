# qBittorrent Neo core: qBittorrent's src/base (+ src/webui) built without
# the Qt Widgets GUI, plus the bridge that hosts it inside the SwiftUI app.
#
# This project includes qBittorrent's own CMake modules and source
# directories from ../qbittorrent without modifying them, the same way
# qbittorrent/CMakeLists.txt does for a GUI=OFF (nox) build.

cmake_minimum_required(VERSION 3.24 FATAL_ERROR)

project(qBittorrentNeoCore
    DESCRIPTION "qBittorrent core hosted in-process for the qBittorrent Neo macOS app"
    LANGUAGES C CXX
)

set(QBT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../qbittorrent")
get_filename_component(QBT_ROOT "${QBT_ROOT}" ABSOLUTE)

# Variables qBittorrent's CMake scripts expect from project(qBittorrent).
set(qBittorrent_SOURCE_DIR "${QBT_ROOT}")
set(qBittorrent_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/qbittorrent")

# Keep in sync with qbittorrent/CMakeLists.txt.
set(minBoostVersion 1.76)
set(minQt6Version 6.6.0)
set(minOpenSSLVersion 3.0.2)
set(minLibtorrent1Version 1.2.19)
set(minLibtorrentVersion 2.0.10)
set(minZlibVersion 1.2.11)

include(GNUInstallDirs)
list(APPEND CMAKE_MODULE_PATH "${QBT_ROOT}/cmake/Modules")
include(FeatureSummary)
include(FeatureOptionsSetup)

# The GUI is the SwiftUI app; the built-in WebUI server stays available.
set(GUI OFF CACHE BOOL "Build qBittorrent's Qt Widgets GUI" FORCE)
feature_option(WEBUI "Enable built-in HTTP server for remote control" ON)
set(STACKTRACE OFF CACHE BOOL "" FORCE)
set(TESTING OFF CACHE BOOL "" FORCE)

include(CheckPackages)
include(CommonConfig)

# Same as qbittorrent/CMakeLists.txt: version.h is generated next to its
# template (the file is ignored by qBittorrent's .gitignore).
configure_file("${QBT_ROOT}/src/base/version.h.in" "${QBT_ROOT}/src/base/version.h" @ONLY)

include_directories("${QBT_ROOT}/src")
add_subdirectory("${QBT_ROOT}/src/base" "${qBittorrent_BINARY_DIR}/src/base")
if (WEBUI)
    add_subdirectory("${QBT_ROOT}/src/webui" "${qBittorrent_BINARY_DIR}/src/webui")
endif()

# Translations of core messages (log, errors) shipped as Qt resources.
file(GLOB QBT_TS_FILES "${QBT_ROOT}/src/lang/*.ts")
set_source_files_properties(${QBT_TS_FILES} PROPERTIES OUTPUT_LOCATION "${qBittorrent_BINARY_DIR}/src/lang")
qt_add_translation(QBT_QM_FILES ${QBT_TS_FILES} OPTIONS -removeidentical -silent)
configure_file("${QBT_ROOT}/src/lang/lang.qrc" "${qBittorrent_BINARY_DIR}/src/lang/lang.qrc" COPYONLY)
if (WEBUI)
    file(GLOB QBT_WEBUI_TS_FILES "${QBT_ROOT}/src/webui/www/translations/*.ts")
    set_source_files_properties(${QBT_WEBUI_TS_FILES}
        PROPERTIES OUTPUT_LOCATION "${qBittorrent_BINARY_DIR}/src/webui/www/translations")
    qt_add_translation(QBT_WEBUI_QM_FILES ${QBT_WEBUI_TS_FILES} OPTIONS -removeidentical -silent)
    configure_file("${QBT_ROOT}/src/webui/www/translations/webui_translations.qrc"
        "${qBittorrent_BINARY_DIR}/src/webui/www/translations/webui_translations.qrc" COPYONLY)
endif()

# The bridge: a dynamic library with a plain C API (include/qbtneo.h) that
# the Swift app links and embeds.
add_library(qbtneocore SHARED
    include/qbtneo.h
    src/addmanager.h
    src/addmanager.cpp
    src/bridge.cpp
    src/corehost.h
    src/corehost.cpp
    src/eventhub.h
    src/eventhub.cpp
    src/jsonutil.h
    src/jsonutil.cpp
    src/neoapplication.h
    src/neoapplication.cpp
    src/registry.h
    src/registry.cpp
    src/api_app.cpp
    src/api_creator.cpp
    src/api_log.cpp
    src/api_preferences.cpp
    src/api_rss.cpp
    src/api_search.cpp
    src/api_torrents.cpp
    src/api_transfer.cpp
    src/maindata.h
    src/maindata.cpp
    src/params.h
    src/params.cpp

    # Unmodified helpers from qBittorrent's application layer.
    "${QBT_ROOT}/src/app/filelogger.h"
    "${QBT_ROOT}/src/app/filelogger.cpp"
    "${QBT_ROOT}/src/app/upgrade.h"
    "${QBT_ROOT}/src/app/upgrade.cpp"

    # Resources the application layer normally links in.
    "${QBT_ROOT}/src/searchengine/searchengine.qrc"
    ${QBT_QM_FILES}
    "${qBittorrent_BINARY_DIR}/src/lang/lang.qrc"
)

target_include_directories(qbtneocore
    PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include"
    PRIVATE "${QBT_ROOT}/src/app"
)
target_link_libraries(qbtneocore PRIVATE qbt_base)
target_compile_definitions(qbtneocore PRIVATE QBTNEO_BUILDING_CORE)
if (WEBUI)
    target_sources(qbtneocore PRIVATE
        ${QBT_WEBUI_QM_FILES}
        "${qBittorrent_BINARY_DIR}/src/webui/www/translations/webui_translations.qrc"
    )
    target_link_libraries(qbtneocore PRIVATE qbt_webui)
endif()

set_target_properties(qbtneocore PROPERTIES
    OUTPUT_NAME qbtneocore
    INSTALL_NAME_DIR "@rpath"
    BUILD_WITH_INSTALL_NAME_DIR ON
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
)

# Exported C symbols only.
target_link_options(qbtneocore PRIVATE
    "LINKER:-exported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/exported_symbols.txt"
    "LINKER:-dead_strip"
    "LINKER:-no_warn_duplicate_libraries"
)

# Command-line smoke test of the bridge (not part of the app).
add_executable(qbtneo-smoke tools/smoke.c)
set_target_properties(qbtneo-smoke PROPERTIES LINKER_LANGUAGE CXX)
target_link_libraries(qbtneo-smoke PRIVATE qbtneocore)
