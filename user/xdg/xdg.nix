{ config, userSettings, ... }:
{
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true;
      music = "${config.home.homeDirectory}/Media/Music";
      videos = "${config.home.homeDirectory}/Media/Videos";
      pictures = "${config.home.homeDirectory}/Media/Pictures";
      templates = "${config.home.homeDirectory}/Templates";
      download = "${config.home.homeDirectory}/Downloads";
      documents = "${config.home.homeDirectory}/Documents";
      desktop = null;
      publicShare = null;
      extraConfig = {
        ARCHIVE = "${config.home.homeDirectory}/Archive";
        VM = "${config.home.homeDirectory}/Machines";
      };
    };

    mimeApps = {
      enable = true;

      associations.added = {
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];

        "application/pdf" = [ "ai.storyteller.pdfcraft.desktop" ];
        "application/postscript" = [ "ai.storyteller.pdfcraft.desktop" ];

        "text/plain" = [ "${userSettings.editor}.desktop" ];
        "application/json" = [ "${userSettings.editor}.desktop" ];
        "application/javascript" = [ "${userSettings.editor}.desktop" ];
        "application/x-sh" = [ "${userSettings.editor}.desktop" ];
        "text/markdown" = [ "${userSettings.editor}.desktop" ];

        "image/jpeg" = [
          "org.gnome.eog.desktop"
          "ai.storyteller.photocraft.desktop"
        ];
        "image/png" = [
          "org.gnome.eog.desktop"
          "ai.storyteller.photocraft.desktop"
        ];
        "image/gif" = [ "org.gnome.eog.desktop" ];
        "image/bmp" = [
          "org.gnome.eog.desktop"
          "ai.storyteller.photocraft.desktop"
        ];
        "image/svg+xml" = [ "org.gnome.eog.desktop" ];
        "image/webp" = [
          "org.gnome.eog.desktop"
          "ai.storyteller.photocraft.desktop"
        ];

        "text/html" = [ "${userSettings.browser}.desktop" ];
        "text/xml" = [ "${userSettings.browser}.desktop" ];
        "application/xhtml+xml" = [ "${userSettings.browser}.desktop" ];
        "x-scheme-handler/http" = [ "${userSettings.browser}.desktop" ];
        "x-scheme-handler/https" = [ "${userSettings.browser}.desktop" ];
        "x-scheme-handler/ftp" = [ "${userSettings.browser}.desktop" ];

        "audio/mpeg" = [ "${userSettings.browser}.desktop" ];
        "audio/ogg" = [ "${userSettings.browser}.desktop" ];
        "audio/wav" = [ "${userSettings.browser}.desktop" ];
        "video/mp4" = [ "${userSettings.browser}.desktop" ];
        "video/webm" = [ "${userSettings.browser}.desktop" ];
        "video/x-matroska" = [ "${userSettings.browser}.desktop" ];

        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [
          "ai.storyteller.wordcraft.desktop"
        ];
        "application/msword" = [ "ai.storyteller.wordcraft.desktop" ];
        "application/vnd.oasis.opendocument.text" = [ "ai.storyteller.wordcraft.desktop" ];

        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [
          "ai.storyteller.gridcraft.desktop"
        ];
        "application/vnd.ms-excel" = [ "ai.storyteller.gridcraft.desktop" ];
        "application/vnd.oasis.opendocument.spreadsheet" = [ "ai.storyteller.gridcraft.desktop" ];
        "text/csv" = [ "ai.storyteller.gridcraft.desktop" ];

        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [
          "ai.storyteller.deckcraft.desktop"
        ];
        "application/vnd.ms-powerpoint" = [
          "ai.storyteller.deckcraft.desktop"
        ];
        "application/vnd.oasis.opendocument.presentation" = [
          "ai.storyteller.deckcraft.desktop"
        ];

        "application/zip" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-zip-compressed" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-rar-compressed" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-gzip" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-bzip2" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-xz" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-bzip-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-xz-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
      };

      defaultApplications = {
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];

        "application/pdf" = [ "ai.storyteller.pdfcraft.desktop" ];
        "application/postscript" = [ "ai.storyteller.pdfcraft.desktop" ];

        "text/plain" = [ "${userSettings.editor}.desktop" ];
        "application/json" = [ "${userSettings.editor}.desktop" ];
        "application/javascript" = [ "${userSettings.editor}.desktop" ];
        "application/x-sh" = [ "${userSettings.editor}.desktop" ];
        "text/markdown" = [ "${userSettings.editor}.desktop" ];

        "image/jpeg" = [ "org.gnome.eog.desktop" ];
        "image/png" = [ "org.gnome.eog.desktop" ];
        "image/gif" = [ "org.gnome.eog.desktop" ];
        "image/bmp" = [ "org.gnome.eog.desktop" ];
        "image/svg+xml" = [ "org.gnome.eog.desktop" ];
        "image/webp" = [ "org.gnome.eog.desktop" ];

        "text/html" = [ "${userSettings.browser}.desktop" ];
        "text/xml" = [ "${userSettings.browser}.desktop" ];
        "application/xhtml+xml" = [ "${userSettings.browser}.desktop" ];
        "x-scheme-handler/http" = [ "${userSettings.browser}.desktop" ];
        "x-scheme-handler/https" = [ "${userSettings.browser}.desktop" ];
        "x-scheme-handler/ftp" = [ "${userSettings.browser}.desktop" ];

        "audio/mpeg" = [ "${userSettings.browser}.desktop" ];
        "audio/ogg" = [ "${userSettings.browser}.desktop" ];
        "audio/wav" = [ "${userSettings.browser}.desktop" ];
        "video/mp4" = [ "${userSettings.browser}.desktop" ];
        "video/webm" = [ "${userSettings.browser}.desktop" ];
        "video/x-matroska" = [ "${userSettings.browser}.desktop" ];

        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [
          "ai.storyteller.wordcraft.desktop"
        ];
        "application/msword" = [ "ai.storyteller.wordcraft.desktop" ];
        "application/vnd.oasis.opendocument.text" = [ "ai.storyteller.wordcraft.desktop" ];

        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [
          "ai.storyteller.gridcraft.desktop"
        ];
        "application/vnd.ms-excel" = [ "ai.storyteller.gridcraft.desktop" ];
        "application/vnd.oasis.opendocument.spreadsheet" = [ "ai.storyteller.gridcraft.desktop" ];
        "text/csv" = [ "ai.storyteller.gridcraft.desktop" ];
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [
          "ai.storyteller.deckcraft.desktop"
        ];
        "application/vnd.ms-powerpoint" = [
          "ai.storyteller.deckcraft.desktop"
        ];
        "application/vnd.oasis.opendocument.presentation" = [
          "ai.storyteller.deckcraft.desktop"
        ];

        "application/zip" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-zip-compressed" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-rar-compressed" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-gzip" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-bzip2" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-xz" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-bzip-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-xz-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
      };
    };
  };
}
