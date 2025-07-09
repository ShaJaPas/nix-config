{ ... }:
{
  # Enable the dunst service
  services.dunst = {
    enable = true;
    settings = {
      global = {
        origin = "top-right";
        offset = "10x50";
        font = "JetBrainsMono Nerd Font 10";
        format = ''<b>%s</b>\n%b'';
        horizontal_padding = 10;
        padding = 8;
        frame_width = 2;
        frame_color = "#3b4252";
        separator_color = "frame";
        sort = true;
        idle_threshold = 120;
        markup = "full";
        show_indicators = true;
        word_wrap = true;
        ellipsize = "middle";
        ignore_newline = false;
        stack_duplicates = true;
        hide_duplicate_count = false;
        line_height = 0;
        corner_radius = 10;
      };
      urgency_low = {
        background = "#2e3440";
        foreground = "#d8dee9";
        timeout = 5;
      };
      urgency_normal = {
        background = "#2e3440";
        foreground = "#d8dee9";
        timeout = 10;
      };
      urgency_critical = {
        background = "#bf616a";
        foreground = "#d8dee9";
        frame_color = "#bf616a";
        timeout = 0;
      };
    };
  };
}
