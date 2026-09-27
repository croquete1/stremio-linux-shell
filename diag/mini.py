# Minimal WebKitGTK 6 window mirroring the shell's widget layout, one knob at a time.
# MINI=plain | offloadonly | transp | overlay | offload
import os, gi
gi.require_version("Gtk", "4.0"); gi.require_version("WebKit", "6.0"); gi.require_version("Gdk", "4.0")
from gi.repository import Gtk, Gdk, WebKit, GLib

mode = os.environ.get("MINI", "plain")
url = os.environ.get("MINI_URL", "https://web.stremio.com/")

def activate(app):
    win = Gtk.ApplicationWindow(application=app, title="Stremio")
    win.set_default_size(1700, 1050)
    web = WebKit.WebView(); web.set_vexpand(True); web.set_hexpand(True)
    if mode not in ("plain", "offloadonly"):
        web.set_background_color(Gdk.RGBA(red=0, green=0, blue=0, alpha=0))
    web.load_uri(url)
    if mode in ("overlay", "offload"):
        ov = Gtk.Overlay()
        # opaque black underlay, like the idle mpv GLArea
        under = Gtk.DrawingArea(); under.set_vexpand(True); under.set_hexpand(True)
        under.set_draw_func(lambda a, cr, w, h: (cr.set_source_rgb(0, 0, 0), cr.paint()))
        ov.set_child(under)
        top = Gtk.GraphicsOffload(child=web, vexpand=True, hexpand=True) if mode == "offload" else web
        ov.add_overlay(top)
        win.set_child(ov)
    elif mode == "offloadonly":
        win.set_child(Gtk.GraphicsOffload(child=web, vexpand=True, hexpand=True))
    else:
        win.set_child(web)
    print("MINI mode", mode, "WebKit", WebKit.get_major_version(), WebKit.get_minor_version(), WebKit.get_micro_version(), flush=True)
    win.present()

app = Gtk.Application(application_id="org.example.Mini" + mode.capitalize())
app.connect("activate", activate)
app.run([])
