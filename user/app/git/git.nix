{
  pkgs,
  userSettings,
  ...
}:

{
  home.packages = [
    pkgs.git
    pkgs.git-crypt
  ];
  programs.git = {
    enable = true;
    userName = userSettings.name;
    userEmail = userSettings.email;
    extraConfig = {
      init.defaultBranch = "master";
      core.editor = "nano";
    };
  };
}
