cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "camera_desktop")
project(${PROJECT_NAME} LANGUAGES CXX)

# Two libraries. camera_desktop_plugin is what Flutter registers: a small
# loader (loader.cc) with no GStreamer dependency, so the app starts on a
# system without GStreamer. camera_desktop_impl is the camera itself, linked to
# GStreamer, bundled in lib/ and opened by the loader at run time. Without the
# GStreamer development files only the loader is built, and the camera reports
# "unsupported".
set(PLUGIN_NAME "camera_desktop_plugin")
set(IMPL_NAME "camera_desktop_impl")

add_library(${PLUGIN_NAME} SHARED "loader.cc")
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PLUGIN_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter PkgConfig::GTK ${CMAKE_DL_LIBS})

find_package(PkgConfig REQUIRED)
pkg_check_modules(GSTREAMER gstreamer-1.0 gstreamer-app-1.0 gstreamer-video-1.0)

if(GSTREAMER_FOUND)
  add_library(${IMPL_NAME} SHARED
    "camera_desktop_plugin.cc"
    "camera_texture.cc"
    "camera.cc"
    "device_enumerator.cc"
    "photo_handler.cc"
    "record_handler.cc"
    "image_stream_ffi.cc"
    "pipewire_portal.cc"
  )
  apply_standard_settings(${IMPL_NAME})
  set_target_properties(${IMPL_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
  target_compile_definitions(${IMPL_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
  target_include_directories(${IMPL_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}" ${GSTREAMER_INCLUDE_DIRS})
  target_link_libraries(${IMPL_NAME} PRIVATE flutter PkgConfig::GTK ${GSTREAMER_LIBRARIES})
  # Its own symbols bind inside it, never to a same-named one already loaded.
  target_link_options(${IMPL_NAME} PRIVATE "-Wl,-Bsymbolic")
  add_dependencies(${PLUGIN_NAME} ${IMPL_NAME})
  set(camera_desktop_bundled_libraries $<TARGET_FILE:${IMPL_NAME}> PARENT_SCOPE)
else()
  message(STATUS "camera_desktop: GStreamer development files not found; building the loader only, "
                 "the camera will report unsupported")
  set(camera_desktop_bundled_libraries "" PARENT_SCOPE)
endif()
