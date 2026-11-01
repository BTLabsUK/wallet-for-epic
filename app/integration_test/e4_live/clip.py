# SPDX-License-Identifier: Apache-2.0
# The sandbox display's clipboard text (the desktop's Copy invite / Copy address), printed. Run with the sandbox env.
import gi
gi.require_version("Gtk","3.0")
from gi.repository import Gtk, Gdk
c=Gtk.Clipboard.get(Gdk.SELECTION_CLIPBOARD)
t=c.wait_for_text()
print(t or "")
