# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(ice_control_sale LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "ice_control_sale")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# flutter_inappwebview_windows 0.7.0-beta.3 uses DEPENDS with the TARGET form
# of add_custom_command. Keep the legacy behavior when configuring that
# dependency so CMake 3.31+ does not emit the CMP0175 developer warning.
set(CMAKE_POLICY_DEFAULT_CMP0175 OLD)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# flutter_inappwebview_windows requires NuGet while configuring WebView2.
# Keep a pinned, checksum-verified project-local copy for reproducible builds.
set(NUGET_VERSION "6.11.1")
set(NUGET_SHA256
  "C0DDC9CB0633C4607DA7E8028EB4F91248C8B74E45A68B0C79FCFA7D78C2A481")
set(NUGET "${CMAKE_BINARY_DIR}/tools/nuget/nuget.exe")
if(NOT EXISTS "${NUGET}")
  file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/tools/nuget")
  file(DOWNLOAD
    "https://dist.nuget.org/win-x86-commandline/v${NUGET_VERSION}/nuget.exe"
    "${NUGET}"
    EXPECTED_HASH "SHA256=${NUGET_SHA256}"
    STATUS NUGET_DOWNLOAD_STATUS
    TLS_VERIFY ON
  )
  list(GET NUGET_DOWNLOAD_STATUS 0 NUGET_DOWNLOAD_CODE)
  list(GET NUGET_DOWNLOAD_STATUS 1 NUGET_DOWNLOAD_MESSAGE)
  if(NOT NUGET_DOWNLOAD_CODE EQUAL 0)
    message(FATAL_ERROR "Unable to download NuGet: ${NUGET_DOWNLOAD_MESSAGE}")
  endif()
endif()
set(NUGET "${NUGET}" CACHE FILEPATH "Project-local NuGet executable" FORCE)

# Serialize writes to compiler program database files. Some plugins compile
# many C++ sources concurrently into one PDB and otherwise fail with C1041.
if(MSVC)
  add_compile_options(/FS)
endif()

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100" /utf-8)
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
# flutter_inappwebview_windows requires nuget.exe to download its native
# dependencies. Keep the executable project-local so Windows builds do not
# depend on a machine-wide NuGet installation.
list(PREPEND CMAKE_PROGRAM_PATH "${CMAKE_CURRENT_SOURCE_DIR}/tools")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

# Keep the runtime Frappe configuration beside the Windows executable.
install(FILES "${CMAKE_SOURCE_DIR}/../setting.json"
  DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

# Keep the editable Bold Reports viewer beside the Windows executable.
install(FILES "${CMAKE_SOURCE_DIR}/../report_viewer.html"
  DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)
