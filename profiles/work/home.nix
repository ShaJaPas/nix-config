{ config, pkgs, userSettings, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = userSettings.username;
  home.homeDirectory = "/home/"+userSettings.username;

  programs.home-manager.enable = true;

  imports = [
              (./. + "../../../user/wm"+("/"+userSettings.wm+"/"+userSettings.wm)+".nix") # My window manager selected from flake
              ../../user/shell/sh.nix # My fish and bash config
              ../../user/shell/cli-collection.nix # Useful CLI apps
              ../../user/shell/starship.nix # Starship config
              ../../user/app/git/git.nix # My git config
              ../../user/app/vscode/vscode.nix # My vscode config
              (./. + "../../../user/app/browser"+("/"+userSettings.browser)+".nix") # My default browser selected from flake
              ../../user/app/virtualization/virtualization.nix # Virtual machines
              ../../user/dev/cc.nix # C stuff
              ../../user/dev/android.nix # Android stuff
              ../../user/dev/python.nix # Python stuff
            ];

  home.stateVersion = "22.11"; # Please read the comment before changing.

  home.packages = (with pkgs; [
    # Core
    fish
    starship
    ghostty
    git

    gnome-tweaks
    wireshark
    bloomrpc
    audio-recorder
    libreoffice-fresh
    stacer
    evince
    telegram-desktop
    htop
    nekoray
    # TODO: разобрать конфиг ниже
    # Office
    /*nextcloud-client
    mate.atril
    openboard
    xournalpp
    gnome.adwaita-icon-theme
    shared-mime-info
    glib
    newsflash
    foliate
    gnome.nautilus
    gnome.gnome-calendar
    gnome.seahorse
    gnome.gnome-maps
    openvpn
    protonmail-bridge
    texliveSmall
    numbat
    element-desktop-wayland

    openai-whisper-cpp

    wine
    bottles

    # Media
    gimp
    krita
    pinta
    inkscape
    vlc
    mpv
    yt-dlp
    blender-hip
    libresprite
    (pkgs.appimageTools.wrapType2 {
      name = "Cura";
      src = fetchurl {
        url = "https://github.com/Ultimaker/Cura/releases/download/5.8.1/UltiMaker-Cura-5.8.1-linux-X64.AppImage";
        hash = "sha256-VLd+V00LhRZYplZbKkEp4DXsqAhA9WLQhF933QAZRX0=";
      };
      extraPkgs = pkgs: with pkgs; [];
     })

    obs-studio
    ffmpeg

    movit
    mediainfo
    libmediainfo
    audio-recorder
    gnome.cheese
    ardour
    rosegarden
    tenacity

    # Various dev packages
    remmina
    sshfs
    texinfo
    libffi zlib
    nodePackages.ungit
    ventoy
    kdenlive*/
  ]);

  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    music = "${config.home.homeDirectory}/Media/Music";
    videos = "${config.home.homeDirectory}/Media/Videos";
    pictures = "${config.home.homeDirectory}/Media/Pictures";
    templates = "${config.home.homeDirectory}/Templates";
    download = "${config.home.homeDirectory}/Downloads";
    documents = "${config.home.homeDirectory}/Documents";
    desktop = null;
    publicShare = null;
    extraConfig = {
      XDG_DOTFILES_DIR = "${config.home.homeDirectory}/.dotfiles";
      XDG_ARCHIVE_DIR = "${config.home.homeDirectory}/Archive";
      XDG_VM_DIR = "${config.home.homeDirectory}/Machines";
    };
  };
  xdg.mime.enable = true;
  xdg.mimeApps.enable = true;
  xdg.mimeApps.associations.added = {
    # TODO fix mime associations, most of them are totally broken :(
    "application/octet-stream" = "flstudio.desktop;";
  };

  home.sessionVariables = {
    EDITOR = userSettings.editor;
    SPAWNEDITOR = userSettings.spawnEditor;
    TERM = userSettings.term;
    BROWSER = userSettings.browser;
  };
}