import gi
gi.require_version('Gtk', '3.0')
gi.require_version('WebKit2', '4.1')
from gi.repository import Gtk, WebKit2

def on_title_changed(webview, param):
    title = webview.get_title()
    if title and title.startswith("SELECTED:"):
        print(title.replace("SELECTED:", ""))
        Gtk.main_quit()

win = Gtk.Window()
win.connect("destroy", Gtk.main_quit)
win.set_default_size(800, 600)

webview = WebKit2.WebView()
webview.connect("notify::title", on_title_changed)
webview.load_uri("file:///home/sniperxmaster/Dranzer/web-wallpaper-selector/index.html")

win.add(webview)
win.show_all()
print("Starting...")
Gtk.main()
