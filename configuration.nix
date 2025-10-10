{
  config,
  pkgs,
  lib,
  hardware,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./vpn.nix
    ./powermanagement.nix
    ./desktop.nix
    ./shell.nix
    #
    ./system/apple-fonts.nix
    ./system/flatpak.nix
    ./system/locale.nix
    ./system/gaming.nix
    ./system/virtualization.nix
    ./system/apps/ledger-live.nix
    # ./system/apps/eufymake-studio.nix
  ];

  # Bootloader.
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "2"; # fajnie jest moc cos przeczytac na ekranie
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };

    kernelPackages = pkgs.linuxPackages_latest;
    blacklistedKernelModules = [
      "hid_lg_g15" # psuje sterowanie jasnoscia wewnetrznego ekranu jak mam podpiete glosniki
    ];
  };

  boot.initrd.luks.devices."luks-baccf639-6b86-41fe-8ec3-a2ecb815b6a1".device =
    "/dev/disk/by-uuid/baccf639-6b86-41fe-8ec3-a2ecb815b6a1";
  networking.hostName = "ramapraca";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.wireless.enable = false; # disable wpa_supplicant
  networking.wireless.iwd.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  virtualisation.docker.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;

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
      "docker"
    ];
    packages = with pkgs; [
      # k8s
      kubectl
      kubernetes-helm
      awscli
      sops
      #
      vscode
      thunderbird
      # chattin
      telegram-desktop
      mumble
      lmstudio
      # devel
      jetbrains.idea-ultimate
      jetbrains.datagrip
      maven
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    nixfmt-rfc-style
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
