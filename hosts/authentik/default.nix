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
  age.secrets.builderSecret = {
    file = ../../secrets/builderSecret;
    # path = "/var/lib/secrets/nextcloudpass";
    # mode = "770";
    # owner = "nextcloud";
  };
  environment.etc."nextcloud-admin-pass".text = "test123";
  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
  };
  local.remoteBuild = {
    enable = true;
    userKeys = config.users.users.sky.openssh.authorizedKeys.keys;
    privKey = config.age.secrets.builderSecret.path;
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
