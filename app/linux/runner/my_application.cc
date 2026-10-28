#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// ATK key listeners, kept here instead of in GTK. GTK 3.24.52 and older walk their own list
// unsafely: the AT-SPI bridge removes its listener from inside that listener's call when the
// last screen reader or AT-SPI client leaves during a key press, and GTK then reads the freed
// list node and crashes in gtk_main_do_event (fixed in GTK commit e6372d29, not yet released).
// This list is walked by key, so a listener removed mid-walk is never touched again.
typedef struct {
  AtkKeySnoopFunc func;
  gpointer data;
  guint key;
} KeyListener;

static GSList* key_listeners = nullptr;

static guint add_key_listener(AtkKeySnoopFunc func, gpointer data) {
  static guint last_key = 0;
  KeyListener* listener = g_new0(KeyListener, 1);
  listener->func = func;
  listener->data = data;
  listener->key = ++last_key;
  key_listeners = g_slist_append(key_listeners, listener);
  return listener->key;
}

static void remove_key_listener(guint key) {
  for (GSList* l = key_listeners; l != nullptr; l = l->next) {
    KeyListener* listener = static_cast<KeyListener*>(l->data);
    if (listener->key == key) {
      key_listeners = g_slist_delete_link(key_listeners, l);
      g_free(listener);
      return;
    }
  }
}

static KeyListener* find_key_listener(guint key) {
  for (GSList* l = key_listeners; l != nullptr; l = l->next) {
    KeyListener* listener = static_cast<KeyListener*>(l->data);
    if (listener->key == key) return listener;
  }
  return nullptr;
}

// The event as GTK hands it to ATK (gtk/a11y/gtkaccessibilityutil.c).
static gint key_snooper(GtkWidget* widget, GdkEventKey* key, gpointer data) {
  if (key_listeners == nullptr) return FALSE;
  AtkKeyEventStruct event{};
  event.type = key->type == GDK_KEY_PRESS ? ATK_KEY_EVENT_PRESS : ATK_KEY_EVENT_RELEASE;
  event.state = key->state;
  event.keyval = key->keyval;
  event.length = key->length;
  if (key->string != nullptr && key->string[0] != '\0' &&
      g_unichar_isgraph(g_utf8_get_char(key->string))) {
    event.string = key->string;
  } else {
    event.string = const_cast<gchar*>(gdk_keyval_name(key->keyval));
  }
  event.keycode = key->hardware_keycode;
  event.timestamp = key->time;

  g_autoptr(GArray) keys = g_array_new(FALSE, FALSE, sizeof(guint));
  for (GSList* l = key_listeners; l != nullptr; l = l->next) {
    g_array_append_val(keys, static_cast<KeyListener*>(l->data)->key);
  }
  gint consumed = FALSE;
  for (guint i = 0; i < keys->len; i++) {
    KeyListener* listener = find_key_listener(g_array_index(keys, guint, i));
    if (listener != nullptr) consumed |= listener->func(&event, listener->data);
  }
  return consumed;
}

// After gtk_init, which sets GTK's own listeners on AtkUtil, and before the bridge adds its
// listener (on the first AT-SPI client).
static void take_over_atk_key_listeners() {
  AtkUtilClass* util = ATK_UTIL_CLASS(g_type_class_ref(ATK_TYPE_UTIL));
  util->add_key_event_listener = add_key_listener;
  util->remove_key_event_listener = remove_key_listener;
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  gtk_key_snooper_install(key_snooper, nullptr);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// The smallest window: the app's deskWindowMinSize (as windows/runner/window_placement.cpp), or
// the work area of the display the pointer is on where that is smaller (1920x1080 at 150% leaves
// about 1280x690). GTK puts these hints back on every resize, over window_manager's own minimum,
// so they have to fit here.
static GdkGeometry& hints_for_display() {
  static GdkGeometry hints{};
  hints.min_width = 800;
  hints.min_height = 700;
  GdkDisplay* display = gdk_display_get_default();
  if (display == nullptr) return hints;
  GdkMonitor* monitor = nullptr;
  GdkSeat* seat = gdk_display_get_default_seat(display);
  GdkDevice* pointer = seat != nullptr ? gdk_seat_get_pointer(seat) : nullptr;
  if (pointer != nullptr) {
    gint x = 0, y = 0;
    gdk_device_get_position(pointer, nullptr, &x, &y);
    monitor = gdk_display_get_monitor_at_point(display, x, y);
  }
  if (monitor == nullptr) monitor = gdk_display_get_primary_monitor(display);
  if (monitor != nullptr) {
    GdkRectangle work;
    gdk_monitor_get_workarea(monitor, &work);
    if (work.width > 0) hints.min_width = MIN(hints.min_width, work.width);
    if (work.height > 0) hints.min_height = MIN(hints.min_height, work.height);
  }
  return hints;
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  // A second start of the app activates this one: show the window it has, never a second one,
  // so two processes never open the same wallet files.
  GList* windows = gtk_application_get_windows(GTK_APPLICATION(application));
  if (windows != nullptr) {
    gtk_window_present(GTK_WINDOW(windows->data));
    return;
  }
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // No header bar: the app draws its own title bar (lib/src/desktop/app/title_bar.dart) and
  // window_manager turns the decorations off before the first frame; the title still names
  // the window in the task switcher.
  gtk_window_set_title(window, "Epic Cash Desktop");

  // The taskbar icon. Taskbars look for a desktop file whose StartupWMClass is the app id; an
  // AppImage started without being installed has none, so they showed a generic gear (#114).
  // The window's own icon (_NET_WM_ICON) is what they fall back to.
  g_autofree gchar* exe = g_file_read_link("/proc/self/exe", nullptr);
  if (exe != nullptr) {
    g_autofree gchar* dir = g_path_get_dirname(exe);
    g_autofree gchar* icon = g_build_filename(dir, "data", "epic-cash-desktop.png", nullptr);
    gtk_window_set_icon_from_file(window, icon, nullptr);
  }

  // Until the app places the window before its first frame (lib/src/desktop/app/
  // window_placement.dart: 80% of the display's work area, the saved size afterwards).
  gtk_window_set_default_size(window, 1280, 820);
  gtk_window_set_geometry_hints(window, nullptr, &hints_for_display(), GDK_HINT_MIN_SIZE);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);
  // Skia by default: on Flutter 3.47 Impeller (its Linux default) costs about six times the CPU
  // per frame on software OpenGL (llvmpipe: VMs, remote desktops, no GPU driver), where every
  // spinner then filled all cores (#126). --impeller opts in, to compare on a given machine;
  // --skia is accepted and means the default (as windows/runner/main.cpp).
  gboolean impeller = FALSE;
  for (gchar** arg = self->dart_entrypoint_arguments; arg != nullptr && *arg != nullptr; arg++) {
    if (g_strcmp0(*arg, "--impeller") == 0) {
      impeller = TRUE;
    } else if (g_strcmp0(*arg, "--skia") == 0) {
      impeller = FALSE;
    }
  }
  fl_dart_project_set_enable_impeller(project, impeller);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
  take_over_atk_key_listeners();
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     static_cast<GApplicationFlags>(0), nullptr));
}
