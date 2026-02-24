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
    settings = {
      user = {
        inherit (userSettings) name email;
      };
      init.defaultBranch = "master";
      core.editor = "nano";
    };
  };
}
