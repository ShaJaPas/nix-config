#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <X11/Xlib.h>
#include <X11/XKBlib.h>

// Global array to store layout names
static char layout_names[XkbNumKbdGroups][16];
static int layouts_initialized = 0;

// Function to initialize layout names from XKB configuration
void initialize_layouts(Display *display) {
    if (layouts_initialized) return;
    
    XkbDescPtr desc = XkbGetKeyboard(display, XkbAllComponentsMask, XkbUseCoreKbd);
    if (!desc) {
        // Fallback defaults
        strcpy(layout_names[0], "us");
        strcpy(layout_names[1], "ru");
        layouts_initialized = 1;
        return;
    }
    
    // Parse symbols string to extract layout names
    if (desc->names && desc->names->symbols != None) {
        char *symbols = XGetAtomName(display, desc->names->symbols);
        if (symbols) {
            // Parse symbols like "pc_us_ru_2_inet(evdev)_group(alt_shift_toggle)"
            char *symbols_copy = strdup(symbols);
            char *token = strtok(symbols_copy, "_");
            int group = 0;
            
            while (token != NULL && group < XkbNumKbdGroups) {
                // Skip non-layout tokens (pc, inet, group, numbers, etc.)
                if (strcmp(token, "pc") != 0 && 
                    strncmp(token, "inet", 4) != 0 && 
                    strncmp(token, "group", 5) != 0 &&
                    strcmp(token, "shift") != 0 &&
                    strcmp(token, "toggle)") != 0 &&
                    strchr(token, '(') == NULL && // skip tokens with parentheses
                    strchr(token, ')') == NULL &&
                    strspn(token, "0123456789") != strlen(token) && // skip pure numbers
                    strlen(token) >= 2 && strlen(token) <= 5) {
                    
                    // Copy layout name
                    strncpy(layout_names[group], token, sizeof(layout_names[group]) - 1);
                    layout_names[group][sizeof(layout_names[group]) - 1] = '\0';
                    group++;
                }
                token = strtok(NULL, "_");
            }
            
            free(symbols_copy);
            XFree(symbols);
        }
    }
    
    XkbFreeKeyboard(desc, 0, True);
    
    // Ensure we have at least one layout
    if (strlen(layout_names[0]) == 0) {
        strcpy(layout_names[0], "us");
    }
    
    layouts_initialized = 1;
}

// Function to get layout name from group number
const char* get_layout_name(Display *display, int group) {
    initialize_layouts(display);
    
    if (group >= 0 && group < XkbNumKbdGroups && strlen(layout_names[group]) > 0) {
        // Convert common layout codes to readable names
        if (strcmp(layout_names[group], "us") == 0) {
            return "en";
        }
        return layout_names[group];
    }
    
    return "unknown";
}

int main() {
    Display *display;
    XEvent event;
    int xkbEventType;
    XkbStateRec state;
    
    // Open display
    display = XOpenDisplay(NULL);
    if (!display) {
        fprintf(stderr, "Cannot open display\n");
        return 1;
    }
    
    // Initialize XKB extension
    if (!XkbQueryExtension(display, NULL, &xkbEventType, NULL, NULL, NULL)) {
        fprintf(stderr, "XKB extension not available\n");
        XCloseDisplay(display);
        return 1;
    }
    
    // Get and output initial layout state
    if (XkbGetState(display, XkbUseCoreKbd, &state) == Success) {
        printf("%s\n", get_layout_name(display, state.group));
        fflush(stdout);
    }
    
    // Select only layout change events (XkbStateNotify with group changes)
    XkbSelectEventDetails(display, XkbUseCoreKbd, XkbStateNotify, 
                         XkbAllStateComponentsMask, XkbGroupStateMask);
    
    // Main event loop
    while (1) {
        XNextEvent(display, &event);
        
        if (event.type == xkbEventType) {
            XkbEvent *xkbEvent = (XkbEvent*)&event;
            
            // Only handle state notifications with group changes (layout changes)
            if (xkbEvent->any.xkb_type == XkbStateNotify) {
                // Output the current layout name
                printf("%s\n", get_layout_name(display, xkbEvent->state.group));
                fflush(stdout);
            }
        }
    }
    
    XCloseDisplay(display);
    return 0;
}
