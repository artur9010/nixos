{ lib, pkgs, inputs, ... }:

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

  programs.command-not-found.enable = true;

  environment.systemPackages = with pkgs; [
    wget
    btop-rocm
    git
    dua
    rclone
    rsync
    restic
    usbutils # lsusb
    pciutils # lspci
    dig
    gnumake
    jq
    yq
    zip
    rar
    _7zz
    #
    goaccess
    duf

    # k8s tools
    kubectl
    kubernetes-helm
    awscli
    sops
    ktop
  ];

  programs.bash.shellAliases = {
    ncdu = "dua i";
  };

}
