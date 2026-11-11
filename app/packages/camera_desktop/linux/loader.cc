// The plugin Flutter registers on Linux: a small loader with no GStreamer
// dependency. It opens libcamera_desktop_impl.so (same sources, linked to
// GStreamer) from its own folder with RTLD_NOW | RTLD_LOCAL, asks it whether
// GStreamer and the elements the pipeline needs are there, and hands it the
// registrar. When the library is missing, does not load, or GStreamer lacks an
// element, it answers every call on the channel with the error code
// "unsupported" and the reason, so the app can say why instead of failing to
// start.
//
// Dart finds the FFI image-stream functions with DynamicLibrary.process(),
// which does not see a library opened RTLD_LOCAL, so the loader exports
// forwarding stubs for them.

#include "include/camera_desktop/camera_desktop_plugin.h"

#include <dlfcn.h>

#include <cstdint>
#include <string>

namespace {

constexpr char kChannel[] = "plugins.flutter.io/camera_desktop";
constexpr char kImplName[] = "libcamera_desktop_impl.so";

using ProbeFn = int (*)(char* reason, size_t reason_len);
using RegisterFn = void (*)(FlPluginRegistrar* registrar);
using GetBufferFn = void* (*)(int64_t);
using RegisterCallbackFn = void (*)(int64_t, void (*)(int32_t));
using UnregisterCallbackFn = void (*)(int64_t);

GetBufferFn g_get_buffer = nullptr;
RegisterCallbackFn g_register_callback = nullptr;
UnregisterCallbackFn g_unregister_callback = nullptr;

std::string ImplPath() {
  Dl_info info = {};
  if (dladdr(reinterpret_cast<void*>(&camera_desktop_plugin_register_with_registrar), &info) == 0 ||
      info.dli_fname == nullptr) {
    return kImplName;
  }
  std::string self(info.dli_fname);
  size_t slash = self.rfind('/');
  if (slash == std::string::npos) return kImplName;
  return self.substr(0, slash + 1) + kImplName;
}

void unsupported_cb(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  const char* reason = static_cast<const char*>(user_data);
  g_autoptr(FlValue) details = fl_value_new_map();
  fl_value_set_string_take(details, "reason", fl_value_new_string(reason));
  fl_method_call_respond_error(method_call, "unsupported", reason, details, nullptr);
}

void RegisterUnsupported(FlPluginRegistrar* registrar, const std::string& reason) {
  g_warning("[camera_desktop] camera unsupported: %s", reason.c_str());
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar), kChannel, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, unsupported_cb, g_strdup(reason.c_str()), g_free);
  // Kept for the life of the process, like the real plugin's channel.
  static FlMethodChannel* kept = nullptr;
  if (kept != nullptr) g_object_unref(kept);
  kept = channel;
}

}  // namespace

void camera_desktop_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  // A test or a support case can force the unsupported path.
  const char* force = g_getenv("CAMERA_DESKTOP_FORCE_UNSUPPORTED");
  if (force != nullptr && force[0] != '\0') {
    RegisterUnsupported(registrar, std::string("forced by CAMERA_DESKTOP_FORCE_UNSUPPORTED"));
    return;
  }
  std::string path = ImplPath();
  void* handle = dlopen(path.c_str(), RTLD_NOW | RTLD_LOCAL);
  if (handle == nullptr) {
    const char* err = dlerror();
    RegisterUnsupported(registrar, std::string("camera support library did not load: ") + (err ? err : path));
    return;
  }
  auto probe = reinterpret_cast<ProbeFn>(dlsym(handle, "camera_desktop_impl_probe"));
  auto reg = reinterpret_cast<RegisterFn>(dlsym(handle, "camera_desktop_impl_register"));
  auto get_buffer = reinterpret_cast<GetBufferFn>(dlsym(handle, "camera_desktop_get_image_stream_buffer"));
  auto register_callback =
      reinterpret_cast<RegisterCallbackFn>(dlsym(handle, "camera_desktop_register_image_stream_callback"));
  auto unregister_callback =
      reinterpret_cast<UnregisterCallbackFn>(dlsym(handle, "camera_desktop_unregister_image_stream_callback"));
  if (!probe || !reg || !get_buffer || !register_callback || !unregister_callback) {
    RegisterUnsupported(registrar, "camera support library is incomplete");
    return;
  }
  char reason[512] = {0};
  if (probe(reason, sizeof(reason)) == 0) {
    RegisterUnsupported(registrar, reason[0] ? reason : "GStreamer is not usable");
    return;
  }
  g_get_buffer = get_buffer;
  g_register_callback = register_callback;
  g_unregister_callback = unregister_callback;
  // The library stays loaded for the life of the process.
  reg(registrar);
}

extern "C" {

__attribute__((visibility("default"))) void camera_desktop_image_stream_noop_callback(int32_t camera_id) {
  (void)camera_id;
}

__attribute__((visibility("default"))) void* camera_desktop_get_image_stream_buffer(int64_t stream_handle) {
  return g_get_buffer ? g_get_buffer(stream_handle) : nullptr;
}

__attribute__((visibility("default"))) void camera_desktop_register_image_stream_callback(int64_t stream_handle,
                                                                                         void (*callback)(int32_t)) {
  if (g_register_callback) g_register_callback(stream_handle, callback);
}

__attribute__((visibility("default"))) void camera_desktop_unregister_image_stream_callback(int64_t stream_handle) {
  if (g_unregister_callback) g_unregister_callback(stream_handle);
}

}  // extern "C"
