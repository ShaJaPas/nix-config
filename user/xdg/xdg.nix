{ config, userSettings, ... }:
{

  xdg = {
    enable = true;
    userDirs = {
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
            XDG_ARCHIVE_DIR = "${config.home.homeDirectory}/Archive";
            XDG_VM_DIR = "${config.home.homeDirectory}/Machines";
        };
    };

    mimeApps = {
        enable = true;
        associations.added = {
            "application/pdf" = ["org.gnome.Evince.desktop"];
            "application/postscript" = ["org.gnome.Evince.desktop"];
            "image/vnd.djvu" = ["org.gnome.Evince.desktop"];

            "text/plain" = ["${userSettings.editor}.desktop"];
            "application/json" = ["${userSettings.editor}.desktop"];
            "application/javascript" = ["${userSettings.editor}.desktop"];
            "application/x-sh" = ["${userSettings.editor}.desktop"];

            "text/markdown" = ["${userSettings.editor}.desktop"];

            "image/jpeg" = ["org.gnome.eog.desktop"];
            "image/png" = ["org.gnome.eog.desktop"];
            "image/gif" = ["org.gnome.eog.desktop"];
            "image/bmp" = ["org.gnome.eog.desktop"];
            "image/svg+xml" = ["org.gnome.eog.desktop"];
            "image/webp" = ["org.gnome.eog.desktop"];

            "text/html" = ["${userSettings.browser}.desktop"];
            "text/xml" = ["${userSettings.browser}.desktop"];
            "application/xhtml+xml" = ["${userSettings.browser}.desktop"];
            "x-scheme-handler/http" = ["${userSettings.browser}.desktop"];
            "x-scheme-handler/https" = ["${userSettings.browser}.desktop"];
            "x-scheme-handler/ftp" = ["${userSettings.browser}.desktop"];

            "audio/mpeg" = ["${userSettings.browser}.desktop"];
            "audio/ogg" = ["${userSettings.browser}.desktop"];
            "audio/wav" = ["${userSettings.browser}.desktop"];
            "video/mp4" = ["${userSettings.browser}.desktop"];
            "video/webm" = ["${userSettings.browser}.desktop"];
            "video/x-matroska" = ["${userSettings.browser}.desktop"];

            "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = ["onlyoffice-desktopeditors.desktop"];
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = ["onlyoffice-desktopeditors.desktop"];
            "application/vnd.openxmlformats-officedocument.presentationml.presentation" = ["onlyoffice-desktopeditors.desktop"];
            "application/vnd.oasis.opendocument.text" = ["onlyoffice-desktopeditors.desktop"];
            "application/vnd.oasis.opendocument.spreadsheet" = ["onlyoffice-desktopeditors.desktop"];
            "application/vnd.oasis.opendocument.presentation" = ["onlyoffice-desktopeditors.desktop"];
            "application/msword" = ["onlyoffice-desktopeditors.desktop"];
            "application/vnd.ms-excel" = ["onlyoffice-desktopeditors.desktop"];
            "application/vnd.ms-powerpoint" = ["onlyoffice-desktopeditors.desktop"];
            "text/csv" = ["onlyoffice-desktopeditors.desktop"];
            };
            defaultApplications = {
            "application/pdf" = ["org.gnome.Evince.desktop"];
            "application/postscript" = ["org.gnome.Evince.desktop"];
            "image/vnd.djvu" = ["org.gnome.Evince.desktop"];

            "text/plain" = ["${userSettings.editor}.desktop"];
            "application/json" = ["${userSettings.editor}.desktop"];
            "application/javascript" = ["${userSettings.editor}.desktop"];
            "application/x-sh" = ["${userSettings.editor}.desktop"];

            "text/markdown" = ["${userSettings.editor}.desktop"];

            "image/jpeg" = ["org.gnome.eog.desktop"];
            "image/png" = ["org.gnome.eog.desktop"];
            "image/gif" = ["org.gnome.eog.desktop"];
            "image/bmp" = ["org.gnome.eog.desktop"];
            "image/svg+xml" = ["org.gnome.eog.desktop"];
            "image/webp" = ["org.gnome.eog.desktop"];

            "text/html" = ["${userSettings.browser}.desktop"];
            "text/xml" = ["${userSettings.browser}.desktop"];
            "application/xhtml+xml" = ["${userSettings.browser}.desktop"];
            "x-scheme-handler/http" = ["${userSettings.browser}.desktop"];
            "x-scheme-handler/https" = ["${userSettings.browser}.desktop"];
            "x-scheme-handler/ftp" = ["${userSettings.browser}.desktop"];

            "audio/mpeg" = ["${userSettings.browser}.desktop"];
            "audio/ogg" = ["${userSettings.browser}.desktop"];
            "audio/wav" = ["${userSettings.browser}.desktop"];
            "video/mp4" = ["${userSettings.browser}.desktop"];
            "video/webm" = ["${userSettings.browser}.desktop"];
            "video/x-matroska" = ["${userSettings.browser}.desktop"];

            "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = ["onlyoffice-desktopeditors.desktop"];
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = ["onlyoffice-desktopeditors.desktop"];
            "application/vnd.openxmlformats-officedocument.presentationml.presentation" = ["onlyoffice-desktopeditors.desktop"];
            "application/vnd.oasis.opendocument.text" = ["onlyoffice-desktopeditors.desktop"];
            "application/vnd.oasis.opendocument.spreadsheet" = ["onlyoffice-desktopeditors.desktop"];
            "application/vnd.oasis.opendocument.presentation" = ["onlyoffice-desktopeditors.desktop"];
            "application/msword" = ["onlyoffice-desktopeditors.desktop"];
            "application/vnd.ms-excel" = ["onlyoffice-desktopeditors.desktop"];
            "application/vnd.ms-powerpoint" = ["onlyoffice-desktopeditors.desktop"];
            "text/csv" = ["onlyoffice-desktopeditors.desktop"];
        };
    };
  };
}