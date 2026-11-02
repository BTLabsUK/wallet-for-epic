{{flutter_js}}
{{flutter_build_config}}

// The web preview's serving rules. On Flutter 3.47 multithreaded
// skwasm corrupts its heap when text changes every frame (flutter#190039, fixed in 3.48), so
// skwasm runs single-threaded and says nothing about it. No service worker: the loader's stub
// only unregisters itself.
_flutter.loader.load({
  config: {
    forceSingleThreadedSkwasm: true,
    suppressMultithreadingWarning: true,
  },
});
