{
  config,
  pkgs,
  lib,
  ...
}: let
  defaultGroups = ["wheel" "docker"];
  max_size = "50g";
  directory = "/var/cache/nginx";
  upsteamUrl = "http://cache.nixos.org";
in {
  security.acme = {
    acceptTerms = true;
    defaults.email = "owner@arouzing.xyz";
  };
  # systemd.tmpfiles.rules = [
  #   "d ${directory} 0660 nginx nginx -"
  # ];
  services.nginx = {
    enable = true;
    appendHttpConfig = ''
      proxy_cache_path ${directory} levels=1:2 keys_zone=cachecache:100m max_size=${max_size} inactive=365d use_temp_path=off;
      
      # Cache only success status codes; in particular we don't want to cache 404s.
      # See https://serverfault.com/a/690258/128321
      map $status $cache_header {
        200     "public";
        302     "public";
        default "no-cache";
      }
      access_log /var/log/nginx/access.log;
    '';
    
    virtualHosts."cache.arouzing.win" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        root = "/var/public-nix-cache";
        extraConfig = ''
          expires max;
          add_header Cache-Control $cache_header always;
          # Ask the upstream server if a file isn't available locally
          error_page 404 = @fallback;
        '';
      };
      
      extraConfig = ''
        # Using a variable for the upstream endpoint to ensure that it is
        # resolved at runtime as opposed to once when the config file is loaded
        # and then cached forever (we don't want that):
        # see https://tenzer.dk/nginx-with-dynamic-upstreams/
        # This fixes errors like
        #   nginx: [emerg] host not found in upstream "upstream.example.com"
        # when the upstream host is not reachable for a short time when
        # nginx is started.
        resolver 1.1.1.1;
        set $upstream_endpoint ${upsteamUrl};
      '';
      
      locations."@fallback" = {
        proxyPass = "$upstream_endpoint";
        extraConfig = ''
          proxy_cache cachecache;
          proxy_cache_valid  200 302  60d;
          expires max;
          add_header Cache-Control $cache_header always;
        '';
      };
      
      # We always want to copy cache.nixos.org's nix-cache-info file,
      # and ignore our own, because `nix-push` by default generates one
      # without `Priority` field, and thus that file by default has priority
      # 50 (compared to cache.nixos.org's `Priority: 40`), which will make
      # download clients prefer `cache.nixos.org` over our binary cache.
      locations."= /nix-cache-info" = {
        # Note: This is duplicated with the `@fallback` above,
        # would be nicer if we could redirect to the @fallback instead.
        proxyPass = "$upstream_endpoint";
        extraConfig = ''
          proxy_cache cachecache;
          proxy_cache_valid  200 302  60d;
          expires max;
          add_header Cache-Control $cache_header always;
        '';
      };
    };
  };

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
  # environment.etc."nextcloud-admin-pass".text = "test123";
  # services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
  #   forceSSL = true;
  #   enableACME = true;
  # };
  local.remoteBuild = {
    enable = true;
    userKeys = config.users.users.sky.openssh.authorizedKeys.keys;
    privKey = config.age.secrets.builderSecret.path;
  };
  services = {
    tailscale.enable = true;
    # nextcloud = {
    #   enable = true;
    #   package = pkgs.nextcloud28;
    #   hostName = "nc.arouzing.win";
    #   https = true;
    #   database.createLocally = true;
    #   config = {
    #     dbtype = "pgsql";
    #     adminpassFile = "/etc/nextcloud-admin-pass";
    #   };
    # };
  };
  networking.firewall.allowedTCPPorts = [443 80];
  system.stateVersion = "23.11";
  # system.autoUpgrade = {
  #   dates = "daily";
  #   enable = true;
  #   allowReboot = false;
  #   randomizedDelaySec = "60min";
  #   flake = "git+https://github.com/JeremiahSecrist/production-servers";
  # };
  networking.hostName = "authentik";
}
