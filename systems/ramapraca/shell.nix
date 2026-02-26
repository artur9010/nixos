{
  lib,
  pkgs,
  inputs,
  ...
}:

{
  # https://www.reddit.com/r/kde/comments/1dbelxh/i_cant_for_the_life_of_me_use_ctrl_alt_fn_keys_to/
  services.kmscon = {
    enable = true;
  };

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
