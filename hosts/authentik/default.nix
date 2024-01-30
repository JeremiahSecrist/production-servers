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
    rbsw = "sudo nixos-rebuild switch --flake";
  };

  # age.secrets.secret1 = {
  #   file = ../../secrets/nextcloudPassword;
  #   # path = "/var/lib/secrets/nextcloudpass";
  #   mode = "770";
  #   owner = "nextcloud";
  # };
  security.pam = {
    enableSSHAgentAuth = true;
    services.sudo.sshAgentAuth = true;
  };
  services = {
    tailscale.enable = true;
    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
      };
      startWhenNeeded = true;
      # kexAlgorithms = [ "curve25519-sha256@libssh.org" ];
    };
  };

  # virtualisation = {
  #   docker = {
  #     enable = true;
  #     liveRestore = true;
  #   };
  # };
  networking.firewall.allowedTCPPorts = [443];
  system.stateVersion = "23.11";
  # system.autoUpgrade = {
  #   dates = "daily";
  #   enable = true;
  #   allowReboot = false;
  #   randomizedDelaySec = "60min";
  #   flake = "github:JeremiahSecrist/linode-nextcloud-nixos";
  # };
  networking.hostName = "authentik";
}
