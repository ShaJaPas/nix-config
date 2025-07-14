import json
import sys
import ewmh
import gi
import os
import configparser
import datetime
import time

gi.require_version('Gtk', '4.0')
from gi.repository import Gtk, Gdk

try:
    from PIL import Image
except ImportError:
    Image = None
try:
    from Xlib import X, error
except ImportError:
    X = None
    error = None

ICON_CACHE_DIR = f"/tmp/eww_icon_cache-{os.getuid()}"
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

def get_and_print_workspaces(e):
    """Get and print workspace and application info, but only if valid data is found."""
    try:
        # It's possible getClientList fails if no clients exist yet.
        # In that case, we can assume an empty list of windows.
        try:
            all_windows = e.getClientList()
            if all_windows is None:
                all_windows = []
        except TypeError: # This happens if _NET_CLIENT_LIST is not set
            all_windows = []

        num_desktops = e.getNumberOfDesktops()
        current_desktop = e.getCurrentDesktop()

        if num_desktops is None or current_desktop is None or num_desktops == 0:
            return # Silently return if WM info is incomplete

    except (error.BadWindow if error else tuple(), AttributeError):
        # An error occurred, likely WM not ready. Don't print, just return.
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

def check_wm_ready(e):
    """Checks if the WM is ready by querying desktop properties, not clients."""
    try:
        num_desktops = e.getNumberOfDesktops()
        current_desktop = e.getCurrentDesktop()
        
        # A WM is ready if it reports at least one desktop.
        if num_desktops is not None and num_desktops > 0 and current_desktop is not None and current_desktop >= 0:
            return True
        return False
    except Exception:
        # Catch potential errors during startup
        return False

def main():
    scan_desktop_files()
    
    e = ewmh.EWMH()

    # For one-shot calls, still try to wait for WM
    # (This part is used by the bspwm.nix debug command)
    if len(sys.argv) > 1 and sys.argv[1] == 'get':
        # For one-shot calls, still try to wait for WM
        if not check_wm_ready(e):
            time.sleep(0.5)
        get_and_print_workspaces(e)
        return

    # Initial setup: Wait in a loop until the WM is fully ready.
    for _ in range(20): # Retry for up to 2 seconds
        if check_wm_ready(e):
            break
        time.sleep(0.1)

    # Now that the WM is ready (or we timed out), print the initial state.
    get_and_print_workspaces(e)

    # Store a set of windows we're listening to for property changes
    listened_windows = set()

    def update_window_event_listeners():
        """Update event listeners for property changes on all windows."""
        nonlocal listened_windows
        try:
            client_list = e.getClientList()
            if client_list is None:
                client_list = []
        except TypeError:
            client_list = []
        current_windows = set(client_list)
        
        new_windows = current_windows - listened_windows
        for win in new_windows:
            try:
                win.change_attributes(event_mask=X.PropertyChangeMask)
            except X.error.BadWindow:
                # Window might have been destroyed before we could add a listener
                pass

        listened_windows = current_windows

    def get_and_print_workspaces_event_handler():
        get_and_print_workspaces(e)

    # Initial listeners are set up after the first successful data fetch
    update_window_event_listeners()

    root = e.root
    root.change_attributes(event_mask=X.PropertyChangeMask)

    # Atoms for properties we are interested in
    NET_CLIENT_LIST_ATOM = e.display.intern_atom('_NET_CLIENT_LIST')
    NET_CURRENT_DESKTOP_ATOM = e.display.intern_atom('_NET_CURRENT_DESKTOP')
    NET_WM_DESKTOP_ATOM = e.display.intern_atom('_NET_WM_DESKTOP')

    # Event loop
    while True:
        try:
            event = e.display.next_event()
            
            # Update everything if the client list, current desktop, or a window's desktop changes
            if hasattr(event, 'atom') and event.atom in [NET_CLIENT_LIST_ATOM, NET_CURRENT_DESKTOP_ATOM, NET_WM_DESKTOP_ATOM]:
                get_and_print_workspaces_event_handler()
                update_window_event_listeners()
            
            # Also update if a property on a listened-to window changes
            elif event.type == X.PropertyNotify:
                get_and_print_workspaces_event_handler()

        except (error.BadWindow if error else tuple(), KeyboardInterrupt):
            # Handle cases where a window is destroyed during processing
            break

if __name__ == "__main__":
    try:
        main()
    except (error.BadWindow if error else tuple(), KeyboardInterrupt):
        # Exit gracefully and silently on known exit conditions.
        pass
    except Exception:
        # On any other unhandled exception, also exit silently.
        pass 