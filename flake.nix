{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
      nixosConfigurations = {
        nextcloud =
          mkNixos defaultSystem [
            nixos-generators.nixosModules.linode
            authentik-nix.nixosModules.default
          ]
          self.nixosModules.authentik;
      };
      nixosModules = {
        authentik = ./hosts/authentik;
        bcachefs = ./profiles/disko;
      };
      formatter.x86_64-linux = pkgs.alejandra;
      checks.${defaultSystem}.default = nixos-lib.runTest (import ./tests/main.nix {inherit self inputs pkgs;});
      # packages.x86_64-linux = {};
      apps.x86_64-linux.agenix = {
        type = "app";
        program = "${agenix.packages.x86_64-linux.agenix}/bin/agenix -i ./secrets/identities/sky $@";
      };
    };
}
