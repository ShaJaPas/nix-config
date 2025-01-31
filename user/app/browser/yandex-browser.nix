{ pkgs, inputs, ... }:

{
  home.packages = [ inputs.yandex-browser.packages.x86_64-linux.yandex-browser-stable ];

  /*
    programs.yandex-browser = {
      enable = true;
      # default is "stable", you can also have "both"
      #package = "beta";
      #extensions = config.programs.chromium.extensions;

      # NOTE: the following are only for nixosModule
      extensionInstallBlocklist = [
        # disable the "buggy" extension in beta

      ];
      homepageLocation = "https://google.com";
      extraOpts = {
        "HardwareAccelerationModeEnabled" = true;
        "DefaultBrowserSettingEnabled" = false;
        "DeveloperToolsAvailability" = 0;
        "CrashesReporting" = false;
        "StatisticsReporting" = false;
        "DistrStatisticsReporting" = false;
        "UpdateAllowed" = false;
        "ImportExtensions" = false;
        "BackgroundModeEnabled" = false;
        "PasswordManagerEnabled" = false;
        "TranslateEnabled" = false;
        "WordTranslatorDisabled" = true;
        "YandexCloudLanguageDetectEnabled" = false;
        "CloudDocumentsDisabled" = true;
        "DefaultGeolocationSetting" = 1;
        "NtpAdsDisabled" = true;
        "NtpContentDisabled" = true;
      };
    };

    home.sessionVariables = {
      DEFAULT_BROWSER = "${pkgs.yandex-browser}/bin/yandex-browser";
    };
  */
}
