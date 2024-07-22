{ config
, pkgs
, lib
, inputs
, ...
}:
let
  defaultGroups = [ "wheel" "docker" ];
  max_size = "50g";
  directory = "/var/cache/nginx";
  upsteamUrl = "http://cache.nixos.org";
in
{
  nixpkgs.overlays = [
    (self: super: {
      unstable = inputs.nixpkgs-unstable.legacyPackages.${self.system};
    })
  ];
  # security.acme = {
  #   acceptTerms = true;
  #   defaults.email = "owner@arouzing.xyz";
  # };
  # systemd.tmpfiles.rules = [
  #   "d ${directory} 0660 nginx nginx -"
  # ];
  # services.nginx = {
  #   enable = true;
  #   appendHttpConfig = ''
  #     proxy_cache_path ${directory} levels=1:2 keys_zone=cachecache:100m max_size=${max_size} inactive=365d use_temp_path=off;

  #     # Cache only success status codes; in particular we don't want to cache 404s.
  #     # See https://serverfault.com/a/690258/128321
  #     map $status $cache_header {
  #       200     "public";
  #       302     "public";
  #       default "no-cache";
  #     }
  #     access_log /var/log/nginx/access.log;
  #   '';

  #   virtualHosts."cache.arouzing.win" = {
  #     forceSSL = true;
  #     enableACME = true;
  #     locations."/" = {
  #       root = "/var/public-nix-cache";
  #       extraConfig = ''
  #         expires max;
  #         add_header Cache-Control $cache_header always;
  #         # Ask the upstream server if a file isn't available locally
  #         error_page 404 = @fallback;
  #       '';
  #     };

  #     extraConfig = ''
  #       # Using a variable for the upstream endpoint to ensure that it is
  #       # resolved at runtime as opposed to once when the config file is loaded
  #       # and then cached forever (we don't want that):
  #       # see https://tenzer.dk/nginx-with-dynamic-upstreams/
  #       # This fixes errors like
  #       #   nginx: [emerg] host not found in upstream "upstream.example.com"
  #       # when the upstream host is not reachable for a short time when
  #       # nginx is started.
  #       resolver 1.1.1.1;
  #       set $upstream_endpoint ${upsteamUrl};
  #     '';

  #     locations."@fallback" = {
  #       proxyPass = "$upstream_endpoint";
  #       extraConfig = ''
  #         proxy_cache cachecache;
  #         proxy_cache_valid  200 302  60d;
  #         expires max;
  #         add_header Cache-Control $cache_header always;
  #       '';
  #     };

  #     # We always want to copy cache.nixos.org's nix-cache-info file,
  #     # and ignore our own, because `nix-push` by default generates one
  #     # without `Priority` field, and thus that file by default has priority
  #     # 50 (compared to cache.nixos.org's `Priority: 40`), which will make
  #     # download clients prefer `cache.nixos.org` over our binary cache.
  #     locations."= /nix-cache-info" = {
  #       # Note: This is duplicated with the `@fallback` above,
  #       # would be nicer if we could redirect to the @fallback instead.
  #       proxyPass = "$upstream_endpoint";
  #       extraConfig = ''
  #         proxy_cache cachecache;
  #         proxy_cache_valid  200 302  60d;
  #         expires max;
  #         add_header Cache-Control $cache_header always;
  #       '';
  #     };
  #   };
  # };

  time.timeZone = lib.mkForce "America/New_York";
  nix = {
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };
  environment.systemPackages = with pkgs; [
    git
  ];
  age = {
    secrets.builderSecret = {
      file = ../../secrets/builderSecret;
      # path = "/var/lib/secrets/nextcloudpass";
      # mode = "770";
      # owner = "nextcloud";
    };
    secrets.githubRunner = {
      file = ../../secrets/githubRunner;
      # path = "/var/lib/secrets/nextcloudpass";
      # mode = "770";
      # owner = "nextcloud";
    };
  };

  # environment.etc."nextcloud-admin-pass".text = "test123";
  # services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
  #   forceSSL = true;
  #   enableACME = true;
  # };
  # local.remoteBuild = {
  #   enable = true;
  #   userKeys = config.users.users.sky.openssh.authorizedKeys.keys;
  #   privKey = config.age.secrets.builderSecret.path;
  # };
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
  virtualisation.docker.enable = true;
  services.github-runners = {
    nixRunner = {
      enable = true;
      replace = true;
      name = "nix-runner";
      tokenFile = config.age.secrets.githubRunner.path;
      url = "https://github.com/JeremiahSecrist/koushinryou-redesign";
      nodeRuntimes = [ "node20" ];
      extraPackages = with pkgs; [
        nodejs_20
        yarn
        gh
        docker
        gawk
        nix
      ];
      extraEnvironment = {
        CHROME_PATH = "${pkgs.chromium}/bin/chromium";
      };
      serviceOverrides = {
        # needed for Cachix installation to work
        ReadWritePaths = [ "/nix/var/nix/profiles/per-user/" ];
        Group = "docker";
        # Allow writing to $HOME
        ProtectHome = "tmpfs";
      };
    };
  };
  services.nginx.virtualHosts."data.arouzing.win" = {
    addSSL = true;
    enableACME = true;
    # root = "/var/www/myhost.org";
  };
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "owner@arouzing.xyz";

  services.wordpress = {
    webserver = "nginx";
    sites."data.arouzing.win" =
      let
        getPlugin = name: version: hash: pkgs.fetchzip {
          inherit name hash;
          url = "https://downloads.wordpress.org/plugin/${name}.${version}.zip";
        };
        a = {
          wpgraphql = (getPlugin "wp-graphql" "1.27.0" "sha256-/FUW2vIvGJD/7XpT2BF9Xt9O1XIH/KlV7Z94pe99ziA=");
          cloudinary = (getPlugin "cloudinary-image-management-and-manipulation-in-the-cloud-cdn" "3.1.8" "sha256-NwCyBIe/OSY146rVR3ejd8wbVj+cY/rGdQDJoI/k2+c=");
          woo = (getPlugin "woocommerce" "9.0.1" "sha256-F2Gf94mMJiFUyHkByDjAF5+EXhbSSZ2hEnoVmP9bDcc=");
          acf = (getPlugin "advanced-custom-fields" "6.3.1" "sha256-+zpG7fM4tCSDzuem9B9bfcsnePRFAJ4fVzevk4HT3UY=");
          acfql = pkgs.stdenv.mkDerivation {
            name = "acfqlql";
            src = pkgs.fetchurl {
              url = "https://github.com/wp-graphql/wpgraphql-acf/releases/download/v2.3.0/wpgraphql-acf.zip";
              hash = "sha256-R4VcCyWNM6I4fWB3RlLIpqHaTjSq32yPiwGuzOZJGK8=";
            };
            buildInputs = [ pkgs.unzip ];
            unpackPhase = "mkdir $out; unzip $src -d $out ";
          };
          wooql = pkgs.stdenv.mkDerivation {
            name = "wooql";
            # Download the theme from the wordpress site
            src = pkgs.fetchurl {
              url = "github.com/wp-graphql/wp-graphql-woocommerce/releases/download/v0.20.0/wp-graphql-woocommerce.zip";
              hash = "sha256-khcA5inSq3DD8IM9BIgB0okVg0SBvr+FbGhXdi7CA0o=";
            };
            # We need unzip to build this package
            buildInputs = [ pkgs.unzip ];
            unpackPhase = "mkdir $out; unzip $src -d $out ";
            # Installing simply means copying all files to the output directory ss
            # installPhase = "mkdir -p $out; cp -r .ext/* $out/";
          };
        };
      in
      {
        database.name = "wp";
        virtualHost.enableACME = true;
        virtualHost.forceSSL = true;
        virtualHost.serverAliases = [
          "authentik.tail3f4f1.ts.net"
        ];
        package = pkgs.unstable.wordpress6_5;
        plugins = a;
      };
  };

  networking.firewall.allowedTCPPorts = [ 443 80 ];
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
