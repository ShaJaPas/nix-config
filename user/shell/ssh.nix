_: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      sendEnv = [ "TERM" ];
      setEnv = {
        TERM = "xterm-256color";
      };
    };
  };

  # Hack to fix SSH warnings/errors due to a file permissions check in fhs env
  home.file.".ssh/config" = {
    target = ".ssh/config_source";
    onChange = "cat ~/.ssh/config_source > ~/.ssh/config && chmod 400 ~/.ssh/config";
  };
}
