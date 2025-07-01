import json
import sys
import ewmh
import gi
import os
import configparser
import datetime

gi.require_version('Gtk', '4.0')
from gi.repository import Gtk, Gdk

try:
    from PIL import Image
except ImportError:
    Image = None
try:
    from Xlib import X
except ImportError:
    X = None

ICON_CACHE_DIR = "/tmp/eww_icon_cache"
if not os.path.exists(ICON_CACHE_DIR):
    os.makedirs(ICON_CACHE_DIR)

DESKTOP_CLASS_MAP = {}

def scan_desktop_files():
    """Scans standard locations for .desktop files and caches their info."""
    if DESKTOP_CLASS_MAP:
        return

    desktop_dirs = [
        '/usr/share/applications',
        '/var/lib/snapd/desktop/applications',
        '/usr/share/applications/kde-org',
        os.path.expanduser('~/.local/share/applications'),
        os.path.expanduser('~/.nix-profile/share/applications'),
        '/run/current-system/sw/share/applications',
    ]

    for d in desktop_dirs:
        if not os.path.isdir(d):
            continue
        for filename in os.listdir(d):
            if not filename.endswith('.desktop'):
                continue
            
            filepath = os.path.join(d, filename)
            parser = configparser.ConfigParser(interpolation=None)
            parser.optionxform = str 
            try:
                parser.read(filepath, encoding='utf-8')
                if 'Desktop Entry' in parser:
                    entry = parser['Desktop Entry']
                    if 'StartupWMClass' in entry:
                        wm_class = entry['StartupWMClass']
                        DESKTOP_CLASS_MAP[wm_class.lower()] = filepath
                    
                    name = os.path.splitext(filename)[0]
                    if name.lower() not in DESKTOP_CLASS_MAP:
                        DESKTOP_CLASS_MAP[name.lower()] = filepath

            except configparser.Error:
                continue

def get_icon_name_from_desktop_file(filepath):
    """Parses a .desktop file and returns the icon name."""
    if not filepath or not os.path.exists(filepath):
        return None
    
    parser = configparser.ConfigParser(interpolation=None)
    parser.optionxform = str
    try:
        parser.read(filepath, encoding='utf-8')
        if 'Desktop Entry' in parser and 'Icon' in parser['Desktop Entry']:
            return parser['Desktop Entry']['Icon']
    except configparser.Error:
        return None
    return None

def get_icon_path_from_theme(icon_name, size=32):
    """Finds the full path of an icon using the current GTK icon theme."""
    if not icon_name:
        return None
    try:
        display = Gdk.Display.get_default()
        theme = Gtk.IconTheme.get_for_display(display)
        
        if os.path.isabs(icon_name) and os.path.exists(icon_name):
            return icon_name
            
        paintable = theme.lookup_icon(icon_name, None, size, 1, Gtk.TextDirection.NONE, 0)
        if paintable:
            icon_file = paintable.get_file()
            if icon_file:
                return icon_file.get_path()
    except Exception:
        return None
    return None

def save_icon_from_data(win_id, icons):
    """Saves an icon from _NET_WM_ICON data to a file."""
    if not Image or not icons:
        return None
    try:
        best_icon = max(icons, key=lambda i: i[0] * i[1])
        width, height, data = best_icon
        img = Image.frombytes("RGBA", (width, height), bytes(data), "raw", "BGRA")
        icon_path = os.path.join(ICON_CACHE_DIR, f"{win_id}.png")
        img.save(icon_path, "PNG")
        return icon_path
    except Exception:
        return None

def get_window_info(win, ewmh_conn):
    """Extracts application info by finding its .desktop file, with fallbacks."""
    icon_path = None
    wm_class = None
    try:
        # Method 1: .desktop file
        wm_class = win.get_wm_class()
        if wm_class:
            class_names_to_try = [c.lower() for c in wm_class if c]
            desktop_filepath = None
            for name in class_names_to_try:
                desktop_filepath = DESKTOP_CLASS_MAP.get(name)
                if desktop_filepath:
                    break
            if desktop_filepath:
                icon_name = get_icon_name_from_desktop_file(desktop_filepath)
                icon_path = get_icon_path_from_theme(icon_name)

        # Method 2: Fallback to direct methods if .desktop fails
        if not icon_path and wm_class:
            class_name = wm_class[0] or wm_class[1]
            if class_name:
                icon_path = get_icon_path_from_theme(class_name.lower())

        # Fallback 2b: get icon from _NET_WM_ICON
        if not icon_path and X:
            try:
                NET_WM_ICON_ATOM = ewmh_conn.display.get_atom('_NET_WM_ICON')
                prop = win.get_full_property(NET_WM_ICON_ATOM, X.AnyPropertyType)
                if prop and prop.value:
                    icons_raw = prop.value
                    icons = []
                    offset = 0
                    while offset < len(icons_raw):
                        width, height = icons_raw[offset], icons_raw[offset+1]
                        if width == 0 or height == 0: break
                        offset += 2
                        size = width * height
                        if offset + size > len(icons_raw): break
                        data = icons_raw[offset : offset + size]
                        icons.append((width, height, data))
                        offset += size
                    if icons:
                        icon_path = save_icon_from_data(win.id, icons)
            except Exception:
                pass

        if icon_path:
            return {"icon": icon_path}
    except Exception:
        pass
    return None

def main():
    scan_desktop_files()
    
    e = ewmh.EWMH()

    # Store a set of windows we're listening to for property changes
    listened_windows = set()

    def update_window_event_listeners():
        """Update event listeners for property changes on all windows."""
        nonlocal listened_windows
        current_windows = set(e.getClientList())
        
        new_windows = current_windows - listened_windows
        for win in new_windows:
            try:
                win.change_attributes(event_mask=X.PropertyChangeMask)
            except X.error.BadWindow:
                # Window might have been destroyed before we could add a listener
                pass

        listened_windows = current_windows

    def get_and_print_workspaces():
        """Get and print workspace and application info."""
        try:
            all_windows = e.getClientList()
            num_desktops = e.getNumberOfDesktops()
            current_desktop = e.getCurrentDesktop()
        except X.error.BadWindow:
            # A window was destroyed while we were querying it.
            # It's safe to just wait for the next event.
            return
        
        workspaces = [{"id": i, "display_id": i + 1, "active": i == current_desktop, "apps": []} for i in range(num_desktops)]

        for win in all_windows:
            desktop_num = e.getWmDesktop(win)
            if desktop_num is not None and 0 <= desktop_num < num_desktops:
                info = get_window_info(win, e)
                if info:
                    workspaces[desktop_num]["apps"].append(info)

        for ws in workspaces:
            ws["occupied"] = bool(ws["apps"])
            if ws["apps"]:
                apps_by_icon = {}
                for app in ws["apps"]:
                    icon = app["icon"]
                    if icon not in apps_by_icon:
                        apps_by_icon[icon] = []
                    apps_by_icon[icon].append(app)
                
                new_apps = []
                for icon, app_list in apps_by_icon.items():
                    new_apps.append({"icon": icon, "count": len(app_list)})
                ws["apps"] = new_apps

        print(json.dumps(workspaces))
        sys.stdout.flush()

    # Initial setup
    get_and_print_workspaces()
    update_window_event_listeners()

    root = e.root
    root.change_attributes(event_mask=X.PropertyChangeMask)

    # Atoms for properties we are interested in
    NET_CLIENT_LIST_ATOM = e.display.intern_atom('_NET_CLIENT_LIST')
    NET_CURRENT_DESKTOP_ATOM = e.display.intern_atom('_NET_CURRENT_DESKTOP')
    NET_WM_DESKTOP_ATOM = e.display.intern_atom('_NET_WM_DESKTOP')

    # Event loop
    while True:
        event = e.display.next_event()
        
        if event.type == X.PropertyNotify:
            if event.atom == NET_CLIENT_LIST_ATOM:

                get_and_print_workspaces()
                update_window_event_listeners()

            elif event.atom in [NET_CURRENT_DESKTOP_ATOM, NET_WM_DESKTOP_ATOM]:
                get_and_print_workspaces()

if __name__ == "__main__":
    try:
        main()
    except (X.error.BadWindow, KeyboardInterrupt):
        # Exit gracefully
        print("[]")
        sys.exit(0)
    except Exception:
        print("[]")
        sys.exit(1) 