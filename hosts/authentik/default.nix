{
  config,
  pkgs,
  lib,
  ...
}: let
  defaultGroups = ["wheel" "docker"];
in {
  time.timeZone = "America/New_York";
  nix = {
    package = pkgs.nix;
    settings.experimental-features = ["nix-command" "flakes"];
  };
  environment.systemPackages = with pkgs; [
    git
    docker-compose
  ];
  programs.bash.shellAliases = {
    rbsw="pushd ~/production-servers ;git pull ;sudo nixos-rebuild switch --flake ~/production-servers ; popd";
  };
  lollypops.deployment = {
    # Where on the remote the configuration (system flake) is placed
    config-dir = "/var/src/lollypops";

    # SSH connection parameters
    ssh.host = "107.172.92.84";
    ssh.user = "sky";
    ssh.command = "ssh";
    ssh.opts = [ "-A" ];

    # sudo options
    sudo.enable = true;
    sudo.command = "sudo";
    # sudo.opts = [];
  };
  # age.secrets.secret1 = {
  #   file = ../../secrets/nextcloudPassword;
  #   # path = "/var/lib/secrets/nextcloudpass";
  #   mode = "770";
  #   owner = "nextcloud";
  # };

  services = {
    tailscale.enable = true;
  };

  # virtualisation = {
  #   docker = {
  #     enable = true;
  #     liveRestore = true;
  #   };
  # };
  networking.firewall.allowedTCPPorts = [443];
  system.stateVersion = "23.11";
  system.autoUpgrade = {
    dates = "daily";
    enable = true;
    allowReboot = false;
    randomizedDelaySec = "60min";
    flake = "git+https://github.com/JeremiahSecrist/production-servers";
  };
  networking.hostName = "authentik";
}
