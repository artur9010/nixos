{ lib, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    syntaxHighlighting = {
      enable = true;
    };
    autosuggestions = {
      enable = true;
    };
    shellAliases = {
      ncdu = "dua i";
    };
    ohMyZsh = {
      enable = true;
      plugins = [
        "docker"
        "git"
        "kubectl"
        "helm"
      ];
      theme = "jispwoso";
    };
  };
  users.defaultUserShell = lib.getExe pkgs.zsh;

  environment.systemPackages = with pkgs; [
    wget
    btop-rocm
    git
    dua
    rclone
    rsync
    restic
    usbutils #lsusb
    pciutils #lspci
    dig
    gnumake
    jq
    yq
  ];

  programs.bash.shellAliases = {
    ncdu = "dua i";
  };

}
