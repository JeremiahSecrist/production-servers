{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/refs/tags/v1.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs.url = "github:serokell/deploy-rs";
    agenix = {
      url = "github:ryantm/agenix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    authentik-nix = {
      url = "github:nix-community/authentik-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-23.11";
    };
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere/refs/tags/1.1.1";
    };
  };
  outputs = inputs:
    with inputs; let
      # supportedSystems = ["x86_64-linux" "x86-linux"];
      defaultSystem = "x86_64-linux";
      specialArgs = { inherit self inputs; };
      nixos-lib = import (nixpkgs + "/nixos/lib") { };
      pkgs = import nixpkgs {
        system = defaultSystem;
      };
      # lib = nixpkgs.lib;
      # forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      sharedModules = [
        agenix.nixosModules.default
        disko.nixosModules.disko
        # deploy-rs.nixosModules.default
      ];
      mkNixos = system: systemModules: config:
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules =
            sharedModules
            ++ systemModules
            ++ [
              config
            ];
        };
    in
    {
      nixosModules = {
        hosts-authentik = ./hosts/authentik;
        disko-btrfs = ./profiles/disko/btrfs;
        hardware-nerdrack = ./profiles/hardware/nerdrack;
        services-remoteBuilder = ./profiles/services/remoteBuilder;
        services-authentik = ./profiles/services/authentik;
        services-mailserver = ./profiles/services/mailserver;
        services-openssh = ./profiles/services/openssh;
        users-sky = ./profiles/users/sky;
      };

      nixosConfigurations = with self.nixosModules; {
        authentik =
          mkNixos defaultSystem [
            authentik-nix.nixosModules.default
            # services-mailserver
            # services-authentik
            # simple-nixos-mailserver.nixosModules.default
            disko-btrfs
            hardware-nerdrack
            services-openssh
            services-remoteBuilder
            users-sky
          ]
            self.nixosModules.hosts-authentik;
      };

      deploy.nodes.authentik = {
        hostname = "arouzing.win";
        profiles = {
          system = {
            user = "root";
            sshUser = "sky";
            sshOpts = [ "-A" ];
            # remoteBuild = true;
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.authentik;
          };
        };
      };
      formatter.x86_64-linux = pkgs.alejandra;
      checks.${defaultSystem}.default = nixos-lib.runTest (import ./tests/main.nix { inherit self inputs pkgs; });
      # packages.x86_64-linux = {};
      apps.x86_64-linux = rec {
        default = deploy;
        secrets = {
          type = "app";
          program = "${agenix.packages.x86_64-linux.default}/bin/agenix";
        };
        install = {
          type = "app";
          program = "${nixos-anywhere.packages.x86_64-linux.nixos-anywhere}/bin/nixos-anywhere";
        };
        deploy = {
          type = "app";
          program = "${deploy-rs.packages.x86_64-linux.deploy-rs}/bin/deploy";
        };
      };
    };
}
