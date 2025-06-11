{
  pkgs,
  lib,
  systemSettings,
  workSettings,
  personalSettings,
  inputs,
  ...
}:
{
  imports = [
    ../../system/hardware-configuration.nix
    ../../system/hardware/systemd.nix # systemd config
    ../../system/hardware/power.nix # Power management
    ../../system/hardware/time.nix # Network time sync
    ../../system/hardware/opengl.nix
    ../../system/hardware/printing.nix
    ../../system/hardware/bluetooth.nix
    (./. + "../../../system/wm" + ("/" + systemSettings.wm) + ".nix") # My window manager
    ../../system/app/virtualization.nix
    (import ../../system/app/docker.nix {
      storageDriver = null;
      inherit pkgs lib;
    })
    ../../system/security/gpg.nix
    ../../system/security/automount.nix
  ];

  # Fix nix path
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=$HOME/nix-config/system/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];

  # Ensure nix flakes are enabled
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # wheel group gets trusted access to nix daemon
  nix.settings.trusted-users = [ "@wheel" ];

  nixpkgs.config.allowUnfree = true;

  # Kernel modules
  boot.kernelModules = [ "cpufreq_powersave" ];
  boot.kernelPackages = inputs.chaotic.legacyPackages.x86_64-linux.linuxPackages_cachyos;

  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
  # Bootloader
  boot.loader = {
    timeout = 5;

    systemd-boot.enable = false;
    efi = {
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;

      efiSupport = true;
      # efiInstallAsRemovable = true; # Otherwise /boot/EFI/BOOT/BOOTX64.EFI isn't generated
      device = systemSettings.grubDevice;
      extraEntriesBeforeNixOS = false;
      copyKernels = false;
      useOSProber = false;
    };
  };

  # Networking
  networking.hostName = systemSettings.hostname; # Define your hostname.
  networking.networkmanager.enable = true; # Use networkmanager

  # Timezone and locale
  time.timeZone = systemSettings.timezone; # time zone
  i18n.defaultLocale = systemSettings.locale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };

  # User account
  users.users.${workSettings.username} = {
    isNormalUser = true;
    initialPassword = "root";
    description = workSettings.name;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "audio"
    ];
    packages = [ ];
  };
  users.users.${personalSettings.username} = {
    isNormalUser = true;
    initialPassword = "root";
    description = personalSettings.name;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "audio"
    ];
    packages = [ ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    wget
    fish
    git
    home-manager
    wpa_supplicant
    networkmanager-vpnc
    networkmanager-openconnect
    gparted
    linuxKernel.packages.linux_zen.perf
  ];

  hardware.enableAllFirmware = true;
  networking.firewall.enable = false;
  services.spice-vdagentd.enable = true;
  programs.nix-ld.enable = true;

  environment.shells = with pkgs; [ fish ];
  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;

  fonts.fontDir.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # It is ok to leave this unchanged for compatibility purposes
  system.stateVersion = "22.11";

}
