{
  pkgs,
  userSettings,
  systemSettings,
  pkgs-stable,
  ...
}:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home = {
    inherit (userSettings) username;
    homeDirectory = "/home/" + userSettings.username;
    stateVersion = "25.11"; # Please read the comment before changing.
    packages = with pkgs; [
      # Core
      fish
      wezterm
      starship
      git

      wireshark
      bloomrpc
      gnome-sound-recorder
      onlyoffice-desktopeditors
      evince
      telegram-desktop
      htop
      pkgs-stable.code-cursor
      openssl
      ffmpeg
      pinta
      obsidian
      eog
      file-roller
      thunderbird
      ansible
    ];
    sessionVariables = {
      BSPWM_SOCKET = "/tmp/bspwm-${userSettings.username}.sock";
      EDITOR = userSettings.editor;
      SPAWNEDITOR = userSettings.spawnEditor;
      TERM = userSettings.term;
      BROWSER = userSettings.browser;
      FZF_DEFAULT_OPTS = "--ansi --preview-window 'right:60%' --preview 'bat --color=always --style=header,grid --line-range :300 {}' --bind 'enter:execute(micro {})'";
      # Force Qt applications to use GTK
      QT_QPA_PLATFORMTHEME = "gtk3";
      #TERM = "xterm-256color";
    };
  };

  programs.home-manager.enable = true;

  imports = [
    (./. + "../../../user/wm" + ("/" + systemSettings.wm + "/" + systemSettings.wm) + ".nix") # My window manager selected from flake
    ../../user/shell/sh.nix # My fish and bash config
    ../../user/shell/wezterm/wezterm.nix # My terminal config
    ../../user/shell/ssh.nix # ssh config
    ../../user/shell/cli-collection.nix # Useful CLI apps
    ../../user/shell/starship.nix # Starship config
    ../../user/app/git/git.nix # My git config
    ../../user/app/vscode/vscode.nix # My vscode config
    ../../user/app/obs-studio/obs.nix # My obs config
    (./. + "../../../user/app/browser" + ("/" + userSettings.browser) + ".nix") # My default browser selected from flake
    ../../user/app/virtualization/virtualization.nix # Virtual machines
    ../../user/dev/cc.nix # C stuff
    ../../user/dev/python.nix # Python stuff
    ../../user/xdg/xdg.nix # XDG
  ];

  programs.java.enable = true;
}
