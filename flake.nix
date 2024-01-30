{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/refs/tags/v1.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
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
    deploy-rs.url = "github:serokell/deploy-rs";
  };
  outputs = inputs:
    with inputs; let
      # supportedSystems = ["x86_64-linux" "x86-linux"];
      defaultSystem = "x86_64-linux";
      specialArgs = {inherit self inputs;};
      nixos-lib = import (nixpkgs + "/nixos/lib") {};
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
    in {
      nixosModules = {
        hosts-authentik = ./hosts/authentik;
        disko-bcachefs = ./profiles/disko/bcachefs;
        hardware-nerdrack = ./profiles/hardware/nerdrack;
        services-authentik = ./profiles/services/authentik;
        services-mailserver = ./profiles/services/mailserver;
        services-openssh = ./profiles/services/openssh;
        users-sky = ./profiles/users/sky;
      };

      nixosConfigurations = {
        authentik =
          mkNixos defaultSystem [
            authentik-nix.nixosModules.default
            simple-nixos-mailserver.nixosModules.default
            self.nixosModules.disko-bcachefs
            self.nixosModules.hardware-nerdrack
            # self.nixosModules.services-mailserver
            self.nixosModules.services-openssh
            self.nixosModules.users-sky
          ]
          self.nixosModules.hosts-authentik;
      };

      # colmena = {
      #   meta = {
      #     nixpkgs = pkgs;
      #     deployment = {
      #       buildOnTarget = true;
      #       targetUser = "sky";
      #     };
      #   };
      # };

      deploy.nodes.authentik = {
        hostname = "107.172.92.84";
        profiles.system = {
          user = "root";
          sshUser = "sky";
          sshOpts = [ "-A" ];
          magicRollback = false;
          remoteBuild = true;
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.authentik;
        };
      };
      formatter.x86_64-linux = pkgs.alejandra;
      checks.${defaultSystem}.default = nixos-lib.runTest (import ./tests/main.nix {inherit self inputs pkgs;});
      # packages.x86_64-linux = {};
      apps.x86_64-linux = {
        agenix = {
          type = "app";
          program = "${agenix.packages.x86_64-linux.agenix}/bin/agenix -i ./secrets/identities/sky $@";
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
