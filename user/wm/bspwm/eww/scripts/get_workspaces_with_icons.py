import json
import sys
import ewmh
import gi
import os
import configparser
import datetime
import time
import logging
import psutil

# Setup logging
LOG_FILE = f"/tmp/eww_icon_script_{os.getuid()}.log"
logging.basicConfig(filename=LOG_FILE,
                    filemode='w',
                    format='%(asctime)s - %(levelname)s - %(message)s',
                    level=logging.INFO)

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
DESKTOP_EXEC_MAP = {}

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
            parser.optionxform = lambda optionstr: optionstr
            try:
                parser.read(filepath, encoding='utf-8')
                if 'Desktop Entry' in parser:
                    entry = parser['Desktop Entry']
                    if 'StartupWMClass' in entry:
                        wm_class = entry['StartupWMClass']
                        DESKTOP_CLASS_MAP[wm_class.lower()] = filepath
                    
                    if 'Exec' in entry:
                        exec_cmd = entry['Exec'].split(' ')[0]
                        exec_name = os.path.basename(exec_cmd)
                        if exec_name.lower() not in DESKTOP_EXEC_MAP:
                             DESKTOP_EXEC_MAP[exec_name.lower()] = filepath

                    name = os.path.splitext(filename)[0]
                    if name.lower() not in DESKTOP_CLASS_MAP:
                        DESKTOP_CLASS_MAP[name.lower()] = filepath

            except configparser.Error as e:
                logging.warning(f"Could not parse desktop file {filepath}: {e}")
                continue

def get_icon_name_from_desktop_file(filepath):
    """Parses a .desktop file and returns the icon name."""
    if not filepath or not os.path.exists(filepath):
        return None
    
    parser = configparser.ConfigParser(interpolation=None)
    parser.optionxform = lambda optionstr: optionstr
    try:
        parser.read(filepath, encoding='utf-8')
        if 'Desktop Entry' in parser and 'Icon' in parser['Desktop Entry']:
            return parser['Desktop Entry']['Icon']
    except configparser.Error as e:
        logging.warning(f"Could not parse desktop file for icon name {filepath}: {e}")
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
    except Exception as e:
        logging.warning(f"Could not get icon path for '{icon_name}': {e}")
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
    except Exception as e:
        logging.warning(f"Could not save icon from data for win {win_id}: {e}")
        return None

def get_pid_from_window(win, ewmh_conn):
    """Gets the PID of the process that owns a window."""
    if not X: return None
    try:
        NET_WM_PID_ATOM = ewmh_conn.display.get_atom('_NET_WM_PID')
        pid_prop = win.get_full_property(NET_WM_PID_ATOM, X.AnyPropertyType)
        if pid_prop and pid_prop.value:
            return pid_prop.value[0]
    except Exception as e:
        logging.warning(f"Could not get PID for window {win.id}: {e}")
    return None

def get_exe_from_pid(pid):
    """Gets the executable name from a PID."""
    if not pid:
        return None
    try:
        process = psutil.Process(pid)
        return process.name()
    except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess) as e:
        logging.info(f"Could not get process name for PID {pid}: {e}")
        return None

def get_window_info(win, ewmh_conn):
    """Extracts application info by finding its .desktop file, with fallbacks."""
    icon_path = None
    
    # Method 1: Get executable from PID and match with .desktop file
    pid = get_pid_from_window(win, ewmh_conn)
    exe_name = get_exe_from_pid(pid)
    if exe_name:
        desktop_filepath = DESKTOP_EXEC_MAP.get(exe_name.lower())
        if desktop_filepath:
            icon_name = get_icon_name_from_desktop_file(desktop_filepath)
            icon_path = get_icon_path_from_theme(icon_name)

    # Method 2: Fallback to WM_CLASS if PID method fails
    if not icon_path:
        try:
            wm_class = win.get_wm_class()
            if wm_class:
                class_names_to_try = [c.lower() for c in wm_class if c]
                desktop_filepath = None
                for name in class_names_to_try:
                    desktop_filepath = DESKTOP_CLASS_MAP.get(name)
                    if desktop_filepath:
                        break
                    if not desktop_filepath:
                        desktop_filepath = DESKTOP_EXEC_MAP.get(name)
                        if desktop_filepath:
                            break
                if desktop_filepath:
                    icon_name = get_icon_name_from_desktop_file(desktop_filepath)
                    icon_path = get_icon_path_from_theme(icon_name)
        except Exception:
            # This can fail if the window is destroyed, so we don't need to log an error.
            pass

    # Method 3: Fallback to get icon from _NET_WM_ICON
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
        except Exception as e:
            logging.warning(f"Could not get _NET_WM_ICON for window {win.id}: {e}")
            pass

    if icon_path:
        return {"icon": icon_path}
    
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

    except Exception as e:
        if error and isinstance(e, error.BadWindow):
            logging.warning(f"A window was destroyed while querying workspaces: {e}")
        else:
            logging.warning(f"Error getting workspace list, WM may not be ready: {e}")
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
    except Exception as e:
        # Catch potential errors during startup
        logging.warning(f"Error checking WM readiness: {e}")
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

    def update_window_event_listeners(ewmh_conn):
        """Update event listeners for property changes on all windows."""
        nonlocal listened_windows
        try:
            client_list = ewmh_conn.getClientList()
            if client_list is None:
                client_list = []
        except TypeError:
            client_list = []
        current_windows = set(client_list)
        
        new_windows = current_windows - listened_windows
        if X:
            for win in new_windows:
                try:
                    win.change_attributes(event_mask=X.PropertyChangeMask)
                except Exception as ex:
                    if error and isinstance(ex, error.BadWindow):
                        # Window might have been destroyed before we could add a listener
                        logging.info(f"Window {win.id} destroyed before event listener attachment.")
                        pass # It's a recoverable error
                    else:
                        logging.warning(f"Could not set event mask on window {win.id}: {ex}")

        listened_windows = current_windows

    def get_and_print_workspaces_event_handler():
        get_and_print_workspaces(e)

    # Initial listeners are set up after the first successful data fetch
    update_window_event_listeners(e)

    if not X:
        logging.warning("Xlib not available, event listening will be disabled.")
        return

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
                update_window_event_listeners(e)
            
            # Also update if a property on a listened-to window changes
            elif event.type == X.PropertyNotify:
                get_and_print_workspaces_event_handler()

        except KeyboardInterrupt:
            logging.info("Script interrupted by user.")
            break
        except Exception as ex:
            if error and isinstance(ex, error.BadWindow):
                logging.warning(f"BadWindow error in event loop, likely a window was destroyed: {ex}")
                continue # This is a recoverable error, so we continue the loop.
            
            logging.error(f"Unexpected error in event loop: {ex}", exc_info=True)
            # To avoid spamming logs on repeated errors, we break the loop.
            break

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logging.info("Script interrupted by user.")
        pass
    except Exception as e:
        if error and isinstance(e, error.BadWindow):
            logging.warning(f"Exiting due to BadWindow error in main: {e}")
        else:
            logging.critical("Unhandled exception in main, exiting.", exc_info=True)
        pass 