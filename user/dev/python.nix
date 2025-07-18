{ pkgs, ... }:

let
  # This creates a Python environment with the required packages.
  # The Python interpreter within this environment will have access to these packages.
  pythonWithPackages = pkgs.python3.withPackages (
    ps: with ps; [
      ewmh # For interacting with EWMH-compliant window managers.
      pillow # For image manipulation (_NET_WM_ICON).
      pygobject3 # For Gtk/Gdk bindings to find icons.
      psutil
    ]
  );

  # These are the system libraries and data required by the Python packages,
  # especially pygobject3, to function correctly.
  systemDeps = with pkgs; [
    gobject-introspection
    gtk4
    (gdk-pixbuf.overrideAttrs (oldAttrs: {
      loaders = [ librsvg ];
    }))
    adwaita-icon-theme
    hicolor-icon-theme
    glib.out
    graphene
    pango.out
    harfbuzz
    gsettings-desktop-schemas
  ];

  # Path for GObject Introspection typelib files.
  giTypelibPath = pkgs.lib.makeSearchPath "lib/girepository-1.0" systemDeps;

  # Path for XDG data files, including icons and schemas.
  xdgDataDirs = pkgs.lib.makeSearchPath "share" systemDeps;

  # This creates a shell script named `python3-glib`.
  python3-glib = pkgs.writeShellScriptBin "python3-glib" ''
    #!${pkgs.runtimeShell}
    # Set environment variables required for GObject-based libraries to find their data.
    export GI_TYPELIB_PATH="${giTypelibPath}''${GI_TYPELIB_PATH:+:}$GI_TYPELIB_PATH"
    export XDG_DATA_DIRS="${xdgDataDirs}''${XDG_DATA_DIRS:+:}$XDG_DATA_DIRS"

    # Execute the Python interpreter from our custom environment, passing all arguments.
    exec ${pythonWithPackages}/bin/python3 "$@"
  '';

in
{
  home.packages = [
    python3-glib
    pkgs.python3Full
  ];
}
