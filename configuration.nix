{
  config,
  pkgs,
  lib,
  hardware,
  ...
}:

{
  imports = [
    ./system/hardware-configuration.nix
    ./system/vpn.nix
    ./system/powermanagement.nix
    ./system/desktop.nix
    ./system/shell.nix
    ./system/apple-fonts.nix
    ./system/flatpak.nix
    ./system/locale.nix
    ./system/gaming.nix
    ./system/virtualization.nix
    ./system/dev.nix
    ./system/apps/ledger-live.nix
    ./system/apps/yafi.nix
  ];

  # Bootloader.
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "2"; # a bit bigger font.
        configurationLimit = 50; # keep last 50 gens in menu
        edk2-uefi-shell.enable = true;
        memtest86.enable = true;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };

    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "amdgpu.cwsr_enable=0" # thanks to amd and their shitty driver, https://community.frame.work/t/attn-critical-bugs-in-amdgpu-driver-included-with-kernel-6-18-x-6-19-x/79221
    ];
    blacklistedKernelModules = [
      "hid_lg_g15" # breaks internal screen brightness control when external logitech z10 speakers are connected
    ];
  };

  boot.kernel.sysctl."kernel.core_pattern" = "/dev/null"; # disable coredumps
  boot.kernel.sysctl."net.ipv4.tcp_congestion_control" = "bbr"; # sounds like something that can help with drops on mobile conn, https://jdecourval.com/ArchLinux/Xiaomi-RedmiBook-Pro-15-2023#sysctls
  boot.initrd.luks.devices."luks-baccf639-6b86-41fe-8ec3-a2ecb815b6a1".device =
    "/dev/disk/by-uuid/baccf639-6b86-41fe-8ec3-a2ecb815b6a1";
  networking.hostName = "ramapraca";

  # Enable networking
  # wpa-supplicant is enabled as nixos-hardware module
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber = {
      enable = true;
      # Disable handsfree profile autoswitch
      extraConfig."51-disable-bluetooth-hfp" = {
        "bluetooth_policy.policy" = {
          "media-role.use-headset-profile" = false;
        };
      };
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.artur9010 = {
    isNormalUser = true;
    description = "Artur Motyka";
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout" # access to serial ports
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    nixfmt
    cifs-utils
  ];

  fileSystems."/mnt/media" = {
    device = "//tower.vpn.craftum.pl/media";
    fsType = "cifs";
    options = [
      "guest"
      "ro"
      "nofail"
      "_netdev"

      "x-systemd.automount"
      "x-systemd.idle-timeout=30s"

      # mount after tailscale starts and before tailscale goes down
      "x-systemd.requires=tailscaled.service"
      "x-systemd.after=tailscaled.service"
      "x-systemd.before=tailscaled.service"

      # shorten mount timeouts
      "x-systemd.mount-timeout=10s"
      "x-systemd.device-timeout=10s"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
