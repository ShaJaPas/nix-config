{
  description = "Flake";

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      # ---- SYSTEM SETTINGS ---- #
      systemSettings = {
        system = "x86_64-linux"; # system arch
        hostname = "konstantin"; # hostname
        profile = "work"; # select a profile defined from my profiles directory
        timezone = "Europe/Moscow"; # select timezone
        locale = "en_US.UTF-8"; # select locale
        grubDevice = "nodev"; # device identifier for grub; only used for legacy (bios) boot mode
        gpuType = "amd"; # amd, intel or nvidia; only makes some slight mods for amd at the moment
        wm = "bspwm"; # Selected window manager or desktop environment; must select one in both ./user/wm/ and ./system/wm/
      };

      # ----- USER SETTINGS ----- #
      workSettings = rec {
        username = "***"; # username
        name = "***"; # name/identifier
        email = "***"; # email (used for certain configurations)
        # window manager type (hyprland or x11) translator
        browser = "yandex-browser"; # Default browser; must select one from ./user/app/browser/
        term = "wezterm"; # Default terminal command;
        editor = "code"; # Default editor;
        # editor spawning translator
        # generates a command that can be used to spawn editor inside a gui
        # EDITOR and TERM session variables must be set in home.nix or other module
        # I set the session variable SPAWNEDITOR to this in my home.nix for convenience
        spawnEditor =
          if (editor == "emacsclient") then
            "emacsclient -c -a 'emacs'"
          else
            (
              if ((editor == "vim") || (editor == "nvim") || (editor == "nano")) then
                "exec " + term + " -e " + editor
              else
                (if (editor == "neovide") then "neovide -- --listen /tmp/nvimsocket" else editor)
            );
      };
      personalSettings = rec {
        username = "***"; # username
        name = "***"; # name/identifier
        email = "***"; # email (used for certain configurations)
        browser = "yandex-browser"; # Default browser; must select one from ./user/app/browser/
        term = "wezterm"; # Default terminal command;
        editor = "code"; # Default editor;
        # editor spawning translator
        # generates a command that can be used to spawn editor inside a gui
        # EDITOR and TERM session variables must be set in home.nix or other module
        # I set the session variable SPAWNEDITOR to this in my home.nix for convenience
        spawnEditor =
          if (editor == "emacsclient") then
            "emacsclient -c -a 'emacs'"
          else
            (
              if ((editor == "vim") || (editor == "nvim") || (editor == "nano")) then
                "exec " + term + " -e " + editor
              else
                (if (editor == "neovide") then "neovide -- --listen /tmp/nvimsocket" else editor)
            );
      };

      pkgs = import inputs.nixpkgs {
        inherit (systemSettings) system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
          allowUnfreePredicate = _: true;
        };
        overlays = [
          (_: super: {
            dunst = super.dunst.overrideAttrs (oldAttrs: {
              patches = (oldAttrs.patches or [ ]) ++ [
                ./patches/dunst-raw-icon.patch
              ];
            });

            go-wrk = pkgs.buildGoModule rec {
              pname = "go-wrk";
              version = "0.10";

              src = pkgs.fetchFromGitHub {
                owner = "tsliwowicz";
                repo = "go-wrk";
                rev = "095f3d71518ba13fcd5521ed6ee48baa9246b0dc";
                hash = "sha256-w3HKSz0iNE13focuUQHufCsoQek70tjxzdwK7fiH2BY=";
              };

              vendorHash = "sha256-rsT9CPLNQa+gTYySoGrVyV3f74huYKfjD+N6VOXzg8Q=";
            };
          })
        ];
      };

      pkgs-stable = import inputs.nixpkgs-stable {
        inherit (systemSettings) system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
          allowUnfreePredicate = _: true;
        };
      };

      inherit (inputs.nixpkgs) lib;
      home-manager = inputs.home-manager-unstable;

    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

      homeConfigurations = {
        work = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./profiles/work/home.nix
            inputs.sops-nix.homeManagerModules.sops
          ];
          extraSpecialArgs = {
            # pass config variables from above
            inherit pkgs-stable;
            inherit systemSettings;
            userSettings = workSettings;
            inherit inputs;
          };
        };
        personal = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./profiles/personal/home.nix
            inputs.sops-nix.homeManagerModules.sops
          ];
          extraSpecialArgs = {
            # pass config variables from above
            inherit pkgs-stable;
            inherit systemSettings;
            userSettings = personalSettings;
            inherit inputs;
          };
        };
      };
      nixosConfigurations = {
        system = lib.nixosSystem {
          inherit (systemSettings) system;
          modules = [
            (./. + "/profiles" + ("/" + systemSettings.profile) + "/configuration.nix")
          ];
          specialArgs = {
            # pass config variables from above
            inherit pkgs-stable;
            inherit pkgs;
            inherit systemSettings;
            inherit workSettings;
            inherit personalSettings;
            inherit inputs;
          };
        };
      };
    };

  inputs = {
    sops-nix.url = "github:mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-24.11";
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      inputs = {
        home-manager.follows = "";
        flake-schemas.follows = "";
        jovian.follows = "";
      };
    };
    #yandex-browser.url = "github:Teu5us/nix-yandex-browser";
    #yandex-browser.inputs.nixpkgs.follows = "nixpkgs";

    home-manager-unstable.url = "github:nix-community/home-manager/master";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs";

    home-manager-stable.url = "github:nix-community/home-manager/release-24.11";
    home-manager-stable.inputs.nixpkgs.follows = "nixpkgs-stable";

    yandex-browser = {
      url = "github:miuirussia/yandex-browser.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
