#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <time.h>
#include <errno.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/Xutil.h>

#define MAX_OUTPUT 8192
#define MAX_WINDOWS 256
#define MAX_CLASSES 64
#define MAX_PATH 512

typedef struct {
    char class_name[256];
    int count;
    char icon_path[MAX_PATH];
} AppInfo;

typedef struct {
    int id;
    char display_id[16];
    int active;
    int occupied;
    AppInfo apps[MAX_CLASSES];
    int app_count;
} WorkspaceInfo;

// Global X11 display
Display *display = NULL;

// Global bspwm socket path
char bspwm_socket_path[256];

// Initialize bspwm socket connection
int init_bspwm_socket() {
    const char* display_name = getenv("DISPLAY");
    const char* host = getenv("BSPWM_SOCKET");
    
    if (host) {
        strncpy(bspwm_socket_path, host, sizeof(bspwm_socket_path) - 1);
        bspwm_socket_path[sizeof(bspwm_socket_path) - 1] = '\0';
    } else {
        // Default socket path
        const char* user = getenv("USER");
        if (!user) user = "unknown";
        snprintf(bspwm_socket_path, sizeof(bspwm_socket_path), "/tmp/bspwm-%s.sock", user);
    }
    
    return 0;
}

// Send command to bspwm via socket and get response
int bspwm_query(const char* command, size_t cmd_len, char* output, size_t output_size) {
    int sock_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sock_fd == -1) {
        return -1;
    }
    
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, bspwm_socket_path, sizeof(addr.sun_path) - 1);
    
    if (connect(sock_fd, (struct sockaddr*)&addr, sizeof(addr)) == -1) {
        close(sock_fd);
        return -1;
    }
    
    // Send command
    if (send(sock_fd, command, cmd_len, 0) != (ssize_t)cmd_len) {
        close(sock_fd);
        return -1;
    }
    
    // Shutdown write end to signal end of command
    shutdown(sock_fd, SHUT_WR);
    
    // Read response
    size_t total_read = 0;
    ssize_t bytes_read;
    
    while (total_read < output_size - 1) {
        bytes_read = recv(sock_fd, output + total_read, output_size - total_read - 1, 0);
        if (bytes_read <= 0) break;
        total_read += bytes_read;
    }
    
    output[total_read] = '\0';
    close(sock_fd);
    
    return total_read > 0 ? 0 : -1;
}

// Execute command and return output (fallback for non-bspwm commands)
int execute_command(const char* cmd, char* output, size_t output_size) {
    FILE* pipe = popen(cmd, "r");
    if (!pipe) return -1;
    
    size_t total = 0;
    char buffer[1024];
    while (fgets(buffer, sizeof(buffer), pipe) && total < output_size - 1) {
        size_t len = strlen(buffer);
        if (total + len < output_size - 1) {
            strcpy(output + total, buffer);
            total += len;
        }
    }
    output[total] = '\0';
    
    int status = pclose(pipe);
    return WEXITSTATUS(status);
}

// Get WM_CLASS for a window using X11
int get_wm_class(Window win, char* class_name, size_t size) {
    if (!display) return 0;
    
    XClassHint class_hint;
    if (XGetClassHint(display, win, &class_hint) == 0) {
        return 0;
    }
    
    if (class_hint.res_class) {
        strncpy(class_name, class_hint.res_class, size - 1);
        class_name[size - 1] = '\0';
        
        // Convert to lowercase
        for (int i = 0; class_name[i]; i++) {
            if (class_name[i] >= 'A' && class_name[i] <= 'Z') {
                class_name[i] = class_name[i] - 'A' + 'a';
            }
        }
        
        XFree(class_hint.res_class);
        if (class_hint.res_name) XFree(class_hint.res_name);
        return 1;
    }
    
    if (class_hint.res_name) XFree(class_hint.res_name);
    return 0;
}

// Create icon if it doesn't exist
int ensure_icon_exists(const char* class_name, Window win, char* icon_path, size_t path_size) {
    const char* cache_dir = getenv("XDG_CACHE_HOME");
    if (!cache_dir) {
        cache_dir = getenv("HOME");
        snprintf(icon_path, path_size, "%s/.cache/window-icons/%s.png", cache_dir, class_name);
    } else {
        snprintf(icon_path, path_size, "%s/window-icons/%s.png", cache_dir, class_name);
    }
    
    // Check if icon already exists
    struct stat st;
    if (stat(icon_path, &st) == 0) {
        return 1; // Icon exists
    }
    
    // Create icon using extract-window-icon
    char cmd[1024];
    char temp_path[MAX_PATH];
    snprintf(temp_path, sizeof(temp_path), "%s.%d.tmp", icon_path, getpid());
    snprintf(cmd, sizeof(cmd), "extract-window-icon 0x%lx %s >/dev/null 2>&1", win, temp_path);
    
    if (system(cmd) == 0) {
        // Move temp file to final location
        if (rename(temp_path, icon_path) == 0) {
            return 1;
        }
    }
    
    // Clean up temp file on failure
    unlink(temp_path);
    return 0;
}

// Helper function to parse lines without strtok
int parse_lines(const char* input, char lines[][256], int max_lines) {
    int line_count = 0;
    const char* start = input;
    const char* end;
    
    while (line_count < max_lines && *start) {
        // Find end of line
        end = strchr(start, '\n');
        if (!end) {
            end = start + strlen(start);
        }
        
        // Copy line
        int len = end - start;
        if (len > 255) len = 255;
        strncpy(lines[line_count], start, len);
        lines[line_count][len] = '\0';
        
        if (len > 0) {
            line_count++;
        }
        
        // Move to next line
        start = (*end == '\n') ? end + 1 : end;
    }
    
    return line_count;
}

// Parse workspace information
int get_workspaces(WorkspaceInfo* workspaces, int max_workspaces) {
    char focused_desktop[256];
    char all_desktops[MAX_OUTPUT];
    char occupied_desktops[MAX_OUTPUT];
    
    // Get focused desktop via bspwm IPC (null-terminated args)
    if (bspwm_query("query\0-D\0-d\0focused\0--names\0", 28, focused_desktop, sizeof(focused_desktop)) != 0) {
        return 0;
    }
    
    // Remove newline
    char* newline = strchr(focused_desktop, '\n');
    if (newline) *newline = '\0';
    
    // Get all desktops via bspwm IPC
    if (bspwm_query("query\0-D\0--names\0", 17, all_desktops, sizeof(all_desktops)) != 0) {
        return 0;
    }
    
    // Get occupied desktops via bspwm IPC
    if (bspwm_query("query\0-D\0--names\0-d\0.occupied\0", 30, occupied_desktops, sizeof(occupied_desktops)) != 0) {
        return 0;
    }
    
    // Parse occupied desktops
    char occupied_lines[32][256];
    int occupied_count = parse_lines(occupied_desktops, occupied_lines, 32);
    
    // Create occupied lookup
    int occupied_lookup[32] = {0};
    for (int i = 0; i < occupied_count; i++) {
        int desk_num = atoi(occupied_lines[i]);
        if (desk_num > 0 && desk_num <= 32) {
            occupied_lookup[desk_num - 1] = 1;
        }
    }
    
    // Parse all desktops
    char desktop_lines[32][256];
    int desktop_count = parse_lines(all_desktops, desktop_lines, 32);
    
    // Process each desktop
    int workspace_count = 0;
    for (int i = 0; i < desktop_count && workspace_count < max_workspaces; i++) {
        WorkspaceInfo* ws = &workspaces[workspace_count];
        int desktop_num = atoi(desktop_lines[i]);
        
        ws->id = desktop_num - 1;
        strncpy(ws->display_id, desktop_lines[i], sizeof(ws->display_id) - 1);
        ws->display_id[sizeof(ws->display_id) - 1] = '\0';
        ws->active = (strcmp(desktop_lines[i], focused_desktop) == 0);
        ws->occupied = occupied_lookup[desktop_num - 1];
        ws->app_count = 0;
        
        if (ws->occupied) {
            // Get windows for this desktop via bspwm IPC
            char cmd[256];
            char windows_output[MAX_OUTPUT];
            
            // Build null-terminated command: "query\0-N\0-d\0{desktop}\0-n\0.window\0"
            int cmd_len = 0;
            cmd_len += sprintf(cmd + cmd_len, "query") + 1;
            cmd_len += sprintf(cmd + cmd_len, "-N") + 1;
            cmd_len += sprintf(cmd + cmd_len, "-d") + 1;
            cmd_len += sprintf(cmd + cmd_len, "%s", desktop_lines[i]) + 1;
            cmd_len += sprintf(cmd + cmd_len, "-n") + 1;
            cmd_len += sprintf(cmd + cmd_len, ".window") + 1;
            
            if (bspwm_query(cmd, cmd_len, windows_output, sizeof(windows_output)) == 0) {
                // Parse window lines
                char window_lines[MAX_WINDOWS][256];
                int window_count = parse_lines(windows_output, window_lines, MAX_WINDOWS);
                
                // Process each window
                for (int j = 0; j < window_count && ws->app_count < MAX_CLASSES; j++) {
                    Window win = strtoul(window_lines[j], NULL, 16);
                    char class_name[256];
                    
                    if (get_wm_class(win, class_name, sizeof(class_name))) {
                        // Find or create app entry
                        int found = 0;
                        for (int k = 0; k < ws->app_count; k++) {
                            if (strcmp(ws->apps[k].class_name, class_name) == 0) {
                                ws->apps[k].count++;
                                found = 1;
                                break;
                            }
                        }
                        
                        if (!found && ws->app_count < MAX_CLASSES) {
                            AppInfo* app = &ws->apps[ws->app_count];
                            strncpy(app->class_name, class_name, sizeof(app->class_name) - 1);
                            app->class_name[sizeof(app->class_name) - 1] = '\0';
                            app->count = 1;
                            
                            if (ensure_icon_exists(class_name, win, app->icon_path, sizeof(app->icon_path))) {
                                ws->app_count++;
                            }
                        }
                    }
                }
            }
        }
        
        workspace_count++;
    }
    
    return workspace_count;
}

// Output JSON
void output_json(WorkspaceInfo* workspaces, int count) {
    printf("[");
    for (int i = 0; i < count; i++) {
        WorkspaceInfo* ws = &workspaces[i];
        
        printf("{\"id\":%d,\"display_id\":\"%s\",\"active\":%s,\"occupied\":%s,\"apps\":[",
               ws->id, ws->display_id,
               ws->active ? "true" : "false",
               ws->occupied ? "true" : "false");
        
        for (int j = 0; j < ws->app_count; j++) {
            AppInfo* app = &ws->apps[j];
            printf("{\"icon\":\"%s\",\"count\":%d}", app->icon_path, app->count);
            if (j < ws->app_count - 1) printf(",");
        }
        
        printf("]}");
        if (i < count - 1) printf(",");
    }
    printf("]\n");
    fflush(stdout);
}

int main(int argc, char* argv[]) {
    // Initialize bspwm socket
    if (init_bspwm_socket() != 0) {
        fprintf(stderr, "Failed to initialize bspwm socket\n");
        return 1;
    }
    
    // Initialize X11
    display = XOpenDisplay(NULL);
    if (!display) {
        fprintf(stderr, "Cannot open X11 display\n");
        return 1;
    }
    
    // Create cache directory
    const char* cache_dir = getenv("XDG_CACHE_HOME");
    char cache_path[MAX_PATH];
    if (!cache_dir) {
        cache_dir = getenv("HOME");
        snprintf(cache_path, sizeof(cache_path), "%s/.cache/window-icons", cache_dir);
    } else {
        snprintf(cache_path, sizeof(cache_path), "%s/window-icons", cache_dir);
    }
    
    char mkdir_cmd[MAX_PATH + 16];
    snprintf(mkdir_cmd, sizeof(mkdir_cmd), "mkdir -p %s", cache_path);
    if (system(mkdir_cmd) != 0) {
        fprintf(stderr, "Warning: Failed to create cache directory\n");
    }
    
    WorkspaceInfo workspaces[32];
    
    if (argc > 1 && strcmp(argv[1], "get") == 0) {
        // Single run mode
        struct timespec start, end;
        clock_gettime(CLOCK_MONOTONIC, &start);
        
        int count = get_workspaces(workspaces, 32);
        if (count > 0) {
            output_json(workspaces, count);
        }
        
        clock_gettime(CLOCK_MONOTONIC, &end);
        double duration = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
        fprintf(stderr, "Update took: %.6fs\n", duration);
    } else {
        // Continuous mode
        // Initial output
        int count = get_workspaces(workspaces, 32);
        if (count > 0) {
            output_json(workspaces, count);
        }
        
        // Subscribe to bspwm events
        FILE* pipe = popen("bspc subscribe desktop_focus node_add node_remove node_transfer", "r");
        if (!pipe) {
            fprintf(stderr, "Failed to subscribe to bspwm events\n");
            XCloseDisplay(display);
            return 1;
        }
        
        char event_line[1024];
        while (fgets(event_line, sizeof(event_line), pipe)) {
            struct timespec start, end;
            clock_gettime(CLOCK_MONOTONIC, &start);
            
            count = get_workspaces(workspaces, 32);
            if (count > 0) {
                output_json(workspaces, count);
            }
            
            clock_gettime(CLOCK_MONOTONIC, &end);
            double duration = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
            fprintf(stderr, "Update took: %.6fs\n", duration);
        }
        
        pclose(pipe);
    }
    
    XCloseDisplay(display);
    return 0;
}
