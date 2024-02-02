{
  config,
  pkgs,
  lib,
  ...
}: let
  defaultGroups = ["wheel" "docker"];
in {
  time.timeZone = lib.mkForce "America/New_York";
  nix = {
    package = pkgs.nix;
    settings.experimental-features = ["nix-command" "flakes"];
  };
  environment.systemPackages = with pkgs; [
    git
  ];
  programs.bash.shellAliases = {
    rbsw = "pushd ~/production-servers ;git pull ;sudo nixos-rebuild switch --flake ~/production-servers ; popd";
  };
  lollypops.deployment = {
    # Where on the remote the configuration (system flake) is placed
    config-dir = "/var/src/lollypops";
    # SSH connection parameters
    ssh = {
      host = "107.172.92.84";
      user = "sky";
      command = "ssh";
      opts = ["-A"];
    };
    # sudo options
    sudo.enable = true;
    # sudo.opts = [];
  };
  # age.secrets.secret1 = {
  #   file = ../../secrets/nextcloudPassword;
  #   # path = "/var/lib/secrets/nextcloudpass";
  #   mode = "770";
  #   owner = "nextcloud";
  # };
  environment.etc."nextcloud-admin-pass".text = "test123";
  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
  };
  services = {
    tailscale.enable = true;
    nextcloud = {
      enable = true;
      package = pkgs.nextcloud28;
      hostName = "nc.arouzing.win";
      https = true;
      database.createLocally = true;
      config = {
        dbtype = "pgsql";
        adminpassFile = "/etc/nextcloud-admin-pass";
      };
    };
  };
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
